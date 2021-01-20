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
    alias :ts :sorter

    # Replaces state rx/tx values with current ones
    def mod st
        st.merge! rx: rx.to_i, tx: tx.to_i
    end

    # Keys which do need to be converted from String to Integer
    def conv_keys
        [:rx, :tx, :rx_last, :tx_last]
    end
    # Convert all values which do need to be converted to Integer
    def to_i
        for key in conv_keys do
            @values[key] = @values[key].to_i
        end
        self
    end

    def to_json *a
        @values.without(:key).to_json(*a)
    end
end

class OpenNebula::TrafficRecords < RecordsSource

    def key
        :vm
    end

    def initialize id, nosync = false
        super(TrafficRecord, id)
        @bill_freq = IONe::Settings['TRAFFIC_BILL_FREQ']
        sync unless nosync
    end

    # Update TrafficRecords with VM monitoring data
    def sync vm = nil
        if vm.nil? then
            vm = onblock :vm, @id
            vm.info!
        end

        last = TrafficRecord.where(vm: vm.id).order(Sequel.asc(:stime)).last # Get last Trafficrecord
        if last.nil? then # Give up if nil
            TrafficRecord.insert(
                vm: @id, rx: "0", tx: "0", rx_last: "0", tx_last: "0", stime: 0, etime: 0
            )
            last = TrafficRecord.where(vm: vm.id).order(Sequel.asc(:stime)).last # Get last Trafficrecord
        end
        last = last.to_i # @see TrafficRecord#to_i

        def next? ts, last # Filter expression
            return !last[:etime].nil? && ts <= last[:etime] # If TrafficRecord is already finished or new record is elder then last update
        end

        # Next block does generate hash structure like { timestamp => {rx, tx} }
        mon_raw = vm.monitoring(['NETTX', 'NETRX'])
        return 0 if OpenNebula.is_error? mon_raw

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

        return 0 if mon.keys.size == 0 # drop if all of the monitoring records has been skipped

        for ts, data in mon do # Writing new data to active record
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

        TrafficRecord.where(stime: last[:stime]).update(**last.values) # Write down updated data

        mon.keys.size # Just for logs
    end

    # Find records between given time and make new active record if last one is bigger than 24h
    def find st, et
        last = TrafficRecord.where(vm: @id).order(Sequel.asc(:stime)).last
        return EmptyQuery.new if last.nil? # EmptyQuerySet for Biller
        if last[:etime] - last[:stime] >= @bill_freq then # If record is elder than 24 hours
            args = last.values.without(:key, :rx, :tx, :stime)
            args.merge! rx: 0, tx: 0, stime: args[:etime] # Setting up new record with zero rx, tx and same rx_last, tx_last
            TrafficRecord.insert(**args)
        end

        @records.exclude(etime: nil).exclude(Sequel.lit('etime - stime < ?', @bill_freq)).where(etime: st..et) # All Records between given time and elder than 24h
    end

    def init_state stime
        state = { rx: 0, tx: 0 }
        rec = TrafficRecord.where(vm: @id).where(etime: stime).all.last
        unless rec.nil? then
            rec = rec.to_i
            state[:rx], state[:tx] = rec.rx, rec.tx
        end
        state
    end
end