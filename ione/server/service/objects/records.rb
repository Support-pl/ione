class Record < Sequel::Model(:records); end

# States and Notifications records object(linked to VM)
class OpenNebula::Records
    attr_reader :id, :records

    # @param [Fixnum] id - VM ID
    def initialize id, type = 'vm'
        @id = id
        @records = Record.where(id:id).where(type:type).to_a # Getting records from DB[table :settings]
        raise NoRecordsError if @records.empty?
    end

    # No records in DB Exception
    class NoRecordsError < StandardError; end
end