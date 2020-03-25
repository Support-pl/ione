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

class Record < Sequel::Model(:records); end

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