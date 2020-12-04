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
class Record < Sequel::Model(:records); end

class SnapshotRecord < Sequel::Model(:snapshot_records); end

class RecordsSource
    attr_reader :id

    def key
        :id
    end

    @@time_delimeter_col = :time

    # @param [Fixnum] id - VM ID
    def initialize cls, id
        @id = id
        @records = cls.where(Hash[key, @id])
    end

    def records
        @records.all
    end

    def find stime, etime
        @records.where(Hash[@@time_delimeter_col, stime..etime])
    end

    def self.tl_filter records
        records
    end
end

class OpenNebula::Records < RecordsSource
    def initialize id
        super(Record, id)
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
        @records.where{
            (((del == nil) | (del >= etime)) & (crt <= stime)) ||
            (crt =~ (stime..etime))
        }
    end
end

