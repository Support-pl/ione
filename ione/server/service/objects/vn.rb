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

class AR < Sequel::Model(:ars)
    def to_json opts = {}
        to_hash.to_json opts
    end
end

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
    def ar_record(ar, per)
        info!
        ar = ar_pool.select{ |o| o['AR_ID'].to_i == ar.to_i }.first
        return {
            ar['IP'] => per * Settings['PUBLIC_IP_COST'].body.to_f
        }
    end
end