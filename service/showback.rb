require "#{ROOT}/service/biller.rb"

# Class for compiling all history records from all records sources into one readable timeline
class Timeline

    attr_reader :vm, :stime, :etime, :group_by_day, :timeline, :sources, :compiled, :state

    SOURCES = [
        Records, SnapshotRecords
    ]

    def initialize vm, stime, etime, group_by_day = false
        @vm, @stime, @etime, @group_by_day = vm, stime, etime, group_by_day
        @sources = SOURCES
        @compiled = false
    end

    def compile
        records = @sources.inject([]) do | r, source |
            r.concat source.tl_filter(
                source.new(@vm.id).find(@stime, @etime).all
            )
        end

        records.map! do | rec |
            rec.sortable
        end
        records.flatten!
    
        @timeline = records.sort_by { |rec| rec.sorter }
        @timeline.select! { |rec| rec.sorter.between?(@stime, @etime)}
        
        init
        init_rec = InitRecord.new @stime, @state
        @timeline.unshift init_rec
        @timeline << FinalRecord.new(@etime)

        @compiled = true
        self
    end

    def init
        @state = @sources.inject({}) do | r, source |
            r.merge source.new(@vm.id).init_state(@stime)
        end
    end

    class InitRecord
        def initialize time, state
            @time, @state = time, state
        end
        def ts
            @time
        end
        def mod st
            st.merge! @state
        end
    end
    class FinalRecord
        def initialize time
            @time = time
        end
        def ts
            @time
        end
    end
end

# Class for billing through Timeline using different billers
class Billing

    attr_reader :timeline, :bill

    BILLERS = [
        CapacityBiller, DiskBiller, SnapshotsBiller
    ]

    def initialize vm, stime, etime
        @vm = vm
        @billers = BILLERS.map { | bill | bill.new(@vm) }
        @billers.select! { |bill| bill.check_biller }

        @timeline = Timeline.new vm, stime, etime
        @timeline.compile
    end

    def make_bill
        state, @bill = {}, []
        @timeline.timeline.each_cons(2) do | curr, con |
            delta = con.ts - curr.ts
            curr.mod state
            bill_rec = {time: con.ts}
            @billers.each do | biller |
                bill_rec.merge! biller.bill(bill_rec, state, delta)
            end
            @bill << bill_rec
        end

        @bill
    end

    def receipt
        @bill.map! do | el |
            el.merge total: el.without(:time).values.sum
        end
    end

    def total
        @bill.inject(0) { |r, el| r += el[:total] }
    end
end

        self
    end
end
