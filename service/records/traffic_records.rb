begin
    $db.create_table :traffic_records do
        primary_key :key
        foreign_key :vm,    :vm_pool,   null: false
        Integer     :ts,    null: false
        String      :rx,    null: false
        String      :tx,    null: false
    end
rescue
    puts "Table :traffic_records already exists, skipping"
end

class TrafficRecord < Sequel::Model(:traffic_records)
    def sortable
        self
    end
    def sorter
        ts
    end
    def mod st
        st[:traffic] = 0
    end
end

class OpenNebula::TrafficRecords < RecordsSource

    def key
        :vm
    end

    def initialize id
        super(TrafficRecord, id)
    end

    def find stime, etime
        @records.where{ ts < stime }.order(Sequel.asc :ts).limit(1)
    end
    
end