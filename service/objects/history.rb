# VMs History Records representation class(linked to VM)
class OpenNebula::History
  require 'nori'

  attr_reader :id, :records

  # @param [Integer] id - VM ID
  # @param [OpenNebula::Client] client
  def initialize id, client
    @client = client
    @id = id
    @parser = Nori.new
  end

  # Getting history records from DB[table :history] and parsing them(from XML)
  def info
    rc = System.new(@client).sql_query_command("SELECT body FROM history WHERE vid=#{@id}")
    rc = @parser.parse rc
    records = rc['SQL_COMMAND']['RESULT']['ROW']
    if records.class == Array then
      records.map! { |record| @parser.parse(Base64.decode64(record['body64'])) }
    else
      records = [@parser.parse(Base64.decode64(records['body64']))]
    end

    @records = records

    nil
  rescue
    NoRecordsError.new "Error occurred while parsing"
  end
  alias_method :info!, :info

  # No records in DB Exception
  class NoRecordsError < StandardError; end
end
