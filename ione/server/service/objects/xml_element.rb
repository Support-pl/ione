# OpenNebula::XMLElement class
class OpenNebula::XMLElement
    # Calls info! method and returns a hash representing the object
    def to_hash!
        self.info! || self.to_hash
    end
    def to_json opts = {}
        to_hash!.to_json opts
    end
end
