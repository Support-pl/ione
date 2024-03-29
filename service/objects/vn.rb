begin
  $db.create_table :ars do
    primary_key :key
    Integer   :vnid,  null: false
    Integer   :arid,  null: false
    Integer   :stime, null: false
    Integer   :etime, null: true
    Integer   :owner, null: true
  end
rescue
  puts "Table :ars already exists, skipping"
end

# Address Range Model class
# @see https://github.com/ione-cloud/ione-sunstone/blob/55a9efd68681829624809b4895a49d750d6e6c34/ione/server/service/objects/vn.rb#L1-L12 AR Model Defintion
class AR < Sequel::Model(:ars)
  # Serializer method
  def to_json opts = {}
    to_hash.to_json opts
  end
end

# Extensions for OpenNebula::VirtualNetwork
class OpenNebula::VirtualNetwork
  #
  # Returns Network Type: Private or Public
  #
  # @return [String]
  #
  def type
    info! || self['TEMPLATE/TYPE']
  end

  #
  # Returns Address Range pool
  #
  # @return [Array<Hash>]
  #
  def ar_pool
    info!
    pool = to_hash['VNET']['AR_POOL']['AR']
    if pool.class == Hash then
      return [pool]
    elsif pool.nil? then
      return []
    else
      return pool
    end
  rescue
    return []
  end

  # Calculate amount of Public Addresses and bill them with `PUBLIC_IP_COST`
  # @param [Integer] ar - AddressRange ID
  # @param [Integer] per - Billing periods amount
  # @return [String|Symbol, Float] - IP address or note and its cost
  def ar_record(ar_id, per)
    info!
    ar = ar_pool.select { |o| o['AR_ID'].to_i == ar_id.to_i }.first
    if ar.nil? && per > 0 then
      return :deleted_ip, per * IONe::Settings['PUBLIC_IP_COST']
    elsif ar.nil? then
      return :trash, 0
    else
      return ar['IP'], per * IONe::Settings['PUBLIC_IP_COST']
    end
  end
end
