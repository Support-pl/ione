class Timeline

    attr_reader :vmid, :stime, :etime, :group_by_day, :timeline

    SOURCES = [
        Records, SnapshotRecords
    ]

    def initialize vm, stime, etime, group_by_day = false
        @vm, @stime, @etime, @group_by_day = vm, stime, etime, group_by_day

        @sources = SOURCES
    end

    def set_state state
        @state = state
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
        
        self
    end
end
