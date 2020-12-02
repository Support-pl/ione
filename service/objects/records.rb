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
        foreign_key :vm, :vm_pool, null: false
        Integer     :id, null: false
        String      :action, size: 3, null: false
    end
rescue
    puts "Table :snapshot_records already exists, skipping"
end

# History Record Model class
# @see https://github.com/ione-cloud/ione-sunstone/blob/55a9efd68681829624809b4895a49d750d6e6c34/ione/server/service/objects/records.rb#L1-L10 History Model Defintion
class Record < Sequel::Model(:records); end

class SnapshotRecord < Sequel::Model(:snapshot_records); end

# States and Notifications records object(linked to VM)
class OpenNebula::Records
    attr_reader :id, :records

    # @param [Fixnum] id - VM ID
    def initialize id
        @id = id
        @records = Record.where(id:id).all # Getting records from DB[table :settings]
        raise NoRecordsError if @records.empty?
    end

    # No records in DB Exception
    class NoRecordsError < StandardError; end
end