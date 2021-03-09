# Source of History records class
class RecordsSource
  attr_reader :id

  # VMID field key
  def key
    :id
  end

  # @param [Fixnum] id - VM ID
  def initialize cls, id
    @id = id
    @records = cls.where(Hash[key, @id])
  end

  # Return all records for this VM(@id)
  def records
    @records.all
  end

  # Find records for given time period
  def find stime, etime
    @records.where(time: stime..etime)
  end

  # Initial timeline state
  def init_state _stime
    {}
  end

  # Filter records needed for Showback Timeline
  def self.tl_filter records
    records
  end

  # Check if source should be used with given VM
  def self.check_source _vm
    true
  end
end

# Imitates empty query
class EmptyQuery
  # Returns empty Array since query is empty
  def all
    return []
  end
end

Dir["#{ROOT}/service/records/*.rb"].each { |file| require file }
