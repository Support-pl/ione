# Extensions for OpenNebula Pool
class OpenNebula::Pool
    # Returns Pool hash after info_all! (so that contains all children objects)
    def to_hash!
        info_all! || to_hash
    end
end