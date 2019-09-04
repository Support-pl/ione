# States and Notifications records object(linked to VM)
class OpenNebula::Records
    attr_reader :id, :records

    # @param [Fixnum] id - VM ID
    def initialize id
        @id = id
        @records = $db[:records].where(id:id).to_a # Getting records from DB[table :settings]
        raise NoRecordsError if @records.empty?
    end

    # No records in DB Exception
    class NoRecordsError < StandardError; end
end