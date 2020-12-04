class Timeline

    attr_reader :vmid, :stime, :etime, :group_by_day, :timeline

    SOURCES = [
        Records, SnapshotRecords
    ]

    def initialize vmid, stime, etime, group_by_day = false
        @vmid, @stime, @etime, @group_by_day = vmid, stime, etime, group_by_day
    end

    def compile
        records = SOURCES.inject([]) do | r, source |
            r.concat source.tl_filter(
                source.new(@vmid).find(@stime, @etime).all
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
