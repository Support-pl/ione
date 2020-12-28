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

    def initialize id, nosync = false
        super(TrafficRecord, id)
        sync unless nosync
    end

    def sync vm = nil
        inserts = 0

        if vm.nil? then
            vm = onblock :vm, @id
            vm.info!
        end

        mon_raw = vm.monitoring(['NETTX', 'NETRX'])
        mon = {}
        mon_raw['NETTX'].each do | el |
            mon[el.first] = {}
            mon[el.first][:tx] = el.last
        end
        mon_raw['NETRX'].each do | el |
            mon[el.first][:rx] = el.last
        end

        last = TrafficRecord.where(vm: vm.id).order(Sequel.asc(:ts)).last
        last = { ts: 0 } if last.nil?

        for ts, data in mon do
            ts = ts.to_i
            if ts > last[:ts] then
                args = data.merge(vm: vm.id, ts: ts)
                TrafficRecord.insert **args
                inserts += 1
            end
        end

        inserts
    end

    def find stime, etime
        @records.where{ ts < stime }.order(Sequel.asc :ts).limit(1)
    end
    
end