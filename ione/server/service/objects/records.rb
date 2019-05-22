class OpenNebula::Records
    attr_reader :id, :records

    def initialize id
        @id = id
        @records = $db[:records].where(id:id).where.to_a
        raise NoRecordsError if @records.empty?
    end

    class NoRecordsError < StandardError; end
end