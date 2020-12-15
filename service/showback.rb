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
        @timeline.select! { |rec| rec.sorter.between?(stime, etime)}
        @compiled = true
        self
    end

    def init
        @state = @sources.inject({}) do | r, source |
            r.merge source.new(@vm.id).init_state(@stime)
        end
    end
end

# Class for billing through Timeline using different billers
class Billing

    attr_reader :timeline

    BILLERS = [
        CapacityBiller
    ]

    def initialize vm, stime, etime
        @vm = vm
        @billers = BILLERS.map { | bill | bill.new(@vm) }
        @billers.select! { |bill| bill.check_biller }

        @timeline = Timeline.new vm, stime, etime
        @timeline.compile
        @timeline.init
    end


    def set_state state
        @state = state
    end
end

        self
    end
end
