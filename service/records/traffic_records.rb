begin
    $db.create_table :traffic_records do
        primary_key :key
        foreign_key :vm,        :vm_pool,   null: false
        String      :rx,        null: false
        String      :rx_last,   null: false
        String      :tx,        null: false
        String      :tx_last,   null: false
        Integer     :stime,     null: false
        Integer     :etime
    end
rescue
    puts "Table :traffic_records already exists, skipping"
end

class TrafficRecord < Sequel::Model(:traffic_records)
    def sortable
        self
    end
    def sorter
        etime
    end
    def mod st
        st.merge! rx: rx, tx: tx
    end

    def conv_keys
        [:rx, :tx, :rx_last, :tx_last]
    end
    def to_i
        for key in conv_keys do
            @values[key] = @values[key].to_i
        end
        self
    end
    def to_s
        for key in conv_keys do
            @values[key] = @values[key].to_s
        end
        self
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
        if vm.nil? then
            vm = onblock :vm, @id
            vm.info!
        end

        last = TrafficRecord.where(vm: vm.id).order(Sequel.asc(:stime)).last
        if last.nil? then
            return 0
        end
        last = last.to_i

        def next? ts, last # Filter expression
            return !last[:etime].nil? && ts <= last[:etime]
        end

        mon_raw = vm.monitoring(['NETTX', 'NETRX'])
        mon = {}
        mon_raw['NETTX'].each do | el |
            el[0] = el[0].to_i
            next if next? el.first, last # Filter records which have been counted
            mon[el.first] = {}
            mon[el.first][:tx] = el.last
        end
        mon_raw['NETRX'].each do | el |
            el[0] = el[0].to_i
            next if next? el.first, last # Filter records which have been counted
            mon[el.first][:rx] = el.last
        end        

        return 0 if mon.keys.size == 0

        for ts, data in mon do
            data[:rx], data[:tx] = data[:rx].to_i, data[:tx].to_i
            last = last.to_i

            if last[:rx_last] > data[:rx] || last[:tx_last] > data[:tx] then
                last[:rx] += data[:rx]
                last[:tx] += data[:tx]
            else
                last[:rx] += (data[:rx] - last[:rx_last])
                last[:tx] += (data[:tx] - last[:tx_last])
            end
            
            last[:rx_last], last[:tx_last] = data[:rx], data[:tx]
            last[:etime] = ts
        end

        last = last.to_s
        TrafficRecord.where(stime: last[:stime]).update(**last.values)

        mon.keys.size
    end

    def find st, et
        last = TrafficRecord.where(vm: @id).order(Sequel.asc(:stime)).last
        if last[:etime] - last[:stime] >= 86400 then # If record is elder than 24 hours
            args = last.values.without(:key, :rx, :tx, :stime)
            args.merge! rx: 0, tx: 0, stime: args[:etime] # Setting up new record with zero rx, tx and same rx_last, tx_last
            TrafficRecord.insert(**args.without(:etime))
        end

        @records.exclude(etime: nil).exclude{ etime - stime < 86400 }.where(etime: st..et)
    end
    end
    
end