require "#{ROOT}/service/biller.rb"

class Timeline

    attr_reader :vm, :stime, :etime, :group_by_day, :timeline, :sources, :compiled

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
        @compiled = true
        self
    end
end

class Billing
    BILLERS = [
        CapacityBiller
    ]

    def initialize vm, stime, etime
        @vm = vm
        @billers = BILLERS.map { | bill | bill.new(vm) }
        @billers.select! { |bill| bill.check_biller }

        @timeline = Timeline.new vm, stime, etime
        @timeline.compile
    end


    def set_state state
        @state = state
    end
end
        
        self
    end
end
