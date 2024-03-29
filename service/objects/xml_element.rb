# Extensions for OpenNebula::XMLElement class
class OpenNebula::XMLElement
  # Calls info! method and returns a hash representing the object
  def to_hash!
    self.info! || self.to_hash
  end

  # Calls info! method and returns a xml representing the object
  def to_xml!
    self.info! || self.to_xml
  end

  # Performs info and returns name
  def name!
    info!
    name
  end

  # Serializer method
  def to_json opts = {}
    to_hash!.to_json opts
  end
end
