# Extensions for OpenNebula Pool
class OpenNebula::Pool
    def to_hash!
        info_all! || to_hash
    end
end