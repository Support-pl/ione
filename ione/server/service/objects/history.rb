class OpenNebula::History
    require 'nori'

    attr_reader :id, :records

    def initialize id, client
        @client = client
        @id = id
        @parser = Nori.new
    end
    def info
        rc = System.new(@client).sql_query_command("SELECT body FROM history WHERE vid=#{@id}")
        rc = @parser.parse rc
        records = rc['SQL_COMMAND']['RESULT']['ROW']
        if records.class == Array then
            records.map! {|record| @parser.parse(Base64.decode64(record['body64'])) }
        else
            records = [ @parser.parse(Base64.decode64(records['body64'])) ]
        end

        @records = records

        nil
    rescue
        NoRecordsError.new "Error occurred while parsing"
    end
    alias_method :info!, :info

    class NoRecordsError < StandardError; end
end