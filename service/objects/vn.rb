begin
    $db.create_table :ars do 
        primary_key :key 
        Integer     :vnid,  null: false
        Integer     :arid,  null: false
        Integer     :time,  null: false
        Integer     :owner, null: true
        String      :state, size: 10,   null: false
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
        else
            return pool
        end
    end
    # Calculate amount of Public Addresses and bill them with `PUBLIC_IP_COST`
    def ar_record(ar, per)
        info!
        ar = ar_pool.select{ |o| o['AR_ID'].to_i == ar.to_i }.first
        return {
            ar['IP'] => per * Settings['PUBLIC_IP_COST'].body.to_f
        }
    end
end