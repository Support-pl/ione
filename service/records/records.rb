begin
    $db.create_table :records do 
        primary_key :key 
        Integer     :id,    null: false
        Integer     :time,  null: false
        String      :state, size: 10,   null: false
    end
rescue
    puts "Table :records already exists, skipping"
end

begin
    $db.create_table :snapshot_records do
        primary_key :key
        foreign_key :vm,  :vm_pool,   null: false
        Integer     :id,  null: false
        Integer     :crt, null: false
        Integer     :del, null: true
    end
rescue
    puts "Table :snapshot_records already exists, skipping"
end

# History Record Model class
# @see https://github.com/ione-cloud/ione-sunstone/blob/55a9efd68681829624809b4895a49d750d6e6c34/ione/server/service/objects/records.rb#L1-L10 History Model Defintion
class Record < Sequel::Model(:records)
    def sortable
        self
    end

    def sorter
        time
    end
    alias :ts :sorter

    # Modifies state by just replacing :state with state from Record
    def mod st
        st[:state] = state
    end
end

class SnapshotRecord < Sequel::Model(:snapshot_records)
    
    # Snapshot Created Record class 
    class CreateSnapshotRecord < SnapshotRecord
        def sorter
            crt
        end
        alias :ts :sorter

        # Increments :snaps
        def mod st
            st[:snaps] += 1
        end
    end
    # Snapshot Deleted Record class 
    class DeleteSnapshotRecord < SnapshotRecord
        def sorter
            del
        end
        alias :ts :sorter

        # Decrements :snaps
        def mod st
            st[:snaps] -= 1
        end
    end
    
    def values
        @values.without(:key)
    end

    # Splits itself into Create- and Delete-(if snap has been deleted) SnapshotRecord
    def sortable
        if self.del then
            [ CreateSnapshotRecord.new(values), DeleteSnapshotRecord.new(values) ]
        else
            CreateSnapshotRecord.new(values)
        end
    end
end

class OpenNebula::Records < RecordsSource
    def initialize id
        super(Record, id)
    end
    def init_state stime
        prev = @records.where{ time < stime }.order(Sequel.desc :time).limit(1).to_a.last
        if prev.nil? then
            {
                'state': @records.where{ time >= stime}.limit(1).to_a.first.state
            }
        else
            {
                state: prev.state
            }
        end
    end
end
class OpenNebula::SnapshotRecords < RecordsSource

    def key
        :vm
    end

    def initialize id
        super(SnapshotRecord, id)
    end
    def find stime, etime
        @records.where(crt: stime..etime).or(del: stime..etime)
    end

    # Gets All of the SnapshotRecords before stime and with deletion time greater than stime or nil and counts(which is initial quantity of snaps)
    def init_state stime
        # SELECT * FROM `snapshot_records` WHERE ((`crt` < 0) AND ((`del` >= 0) OR NOT `del`))
        {
            snaps: @records.where{ crt < stime }.where{(del >= stime) | ~del}.count
        }
    end
end
