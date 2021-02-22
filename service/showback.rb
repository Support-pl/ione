require "#{ROOT}/service/records.rb"
require "#{ROOT}/service/biller.rb"

# Class for compiling all history records from all records sources into one readable timeline
class Timeline

    attr_reader :vm, :stime, :etime, :group_by_day, :timeline, :sources, :compiled, :state

    SOURCES = [ # Should be generated automaticaly in the future
        Records, SnapshotRecords, TrafficRecords
    ]

    # Initializes timeline - collects record sources(yet staticly) and stores entry vars
    def initialize vm, stime, etime, group_by_day = false
        @vm, @stime, @etime, @group_by_day = vm, stime, etime, group_by_day
        @sources = SOURCES
        @compiled = false
    end

    # Compiles timeline: 
    #   obtains events from sources and filters useless events
    #   sorts events
    #   filters again
    def compile
        records = @sources.inject([]) do | r, source |
            r.concat source.tl_filter( # Filtering useless events(e.g. unfinished TrafficRecord)
                source.new(@vm.id).find(@stime, @etime).all # Seeking for all events happend between stime and etime
            )
        end

        records.map! do | rec |
            rec.sortable # Some of Records need to be processed extra to become sortable and usable(for example SnapshotRecords are holding both creation and deletion time, so each SnapshotRecord will be splitted into SnapshotCreateRecord and SnapshotDeleteRecord)
        end
        records.flatten!
    
        @timeline = records.sort_by { |rec| rec.sorter } # Sorting records by time sorter(.sorter method returns timestamp to be used as sorter)
        @timeline.select! { |rec| rec.sorter.between?(@stime, @etime)} # Filtering records again
        
        init # Generating initial state
        init_rec = InitRecord.new @stime, @state
        @timeline.unshift init_rec
        @timeline << FinalRecord.new(@etime)

        @compiled = true
        self
    end

    # Generates initial state
    # @example VM was turned off a minute before stime, which means init state must be 'off' and versa
    # @example VM Snapshot was created a minute before stime, which means init state must have 'snaps: 1'
    def init
        @state = @sources.inject({}) do | r, source |
            r.merge source.new(@vm.id).init_state(@stime)
        end
    end

    # InitRecord class to put into the beginning of the Timeline to make it easier to work with deltas
    class InitRecord
        # Just saves given time and state
        def initialize time, state
            @time, @state = time, state
        end
        # Returns @time
        def ts
            @time
        end
        # Merges init state into state
        def mod st
            st.merge! @state
        end
    end
    # Same as InitRecord but for the end of Timeline
    class FinalRecord
        # Just saves given time
        def initialize time
            @time = time
        end
        # Returns @time
        def ts
            @time
        end
    end
end

# Class for billing through Timeline using different billers
class Billing

    attr_reader :timeline, :bill

    BILLERS = [ # Should be generated automaticaly in the future
        CapacityBiller, DiskBiller, SnapshotsBiller, TrafficBiller
    ]

    # Collects existing billers(yet static), filters them by Biller#check_biller and inits Timeline
    def initialize vm, stime, etime
        @vm = vm
        @billers = BILLERS.map { | bill | bill.new(@vm) }
        # Filtering billers to exclude Billers which won't bill anything. For example there is no Price for Snapshots, so there is no point of billing snapshots for given VM
        @billers.select! { |bill| bill.check_biller } 

        # Compiling VM Timeline with all of the Events(Records)
        @timeline = Timeline.new vm, stime, etime
        @timeline.compile
    end

    # Generate monstous Hash with debits for each and every event
    def make_bill
        state, @bill = {}, []
        # Every Record can and will modify VM state at current time, and then Biller will add data to bill basing on current state and time to next event
        @timeline.timeline.each_cons(2) do | curr, con |
            delta = con.ts - curr.ts
            curr.mod state
            bill_rec = {time: con.ts}
            @billers.each do | biller |
                bill_rec.merge! biller.bill(bill: bill_rec, state: state, delta: delta, record: curr)
            end
            @bill << bill_rec
        end

        @bill
    end

    # Just Adding total to Bill
    def receipt
        @bill.map! do | el |
            el.merge total: el.without(:time).values.sum
        end
    end

    # Calculates total cost
    def total
        @bill.inject(0) { |r, el| r += el[:total] }
    end
end