# Extensions for OpenNebula::Template class
class OpenNebula::Template
  # Checks given template OS type by User Input
  # @return [Boolean]
  def win?
    self.info!
    user_inputs = self.to_hash['VMTEMPLATE']['TEMPLATE']['USER_INPUTS']
    !(user_inputs.nil?) && (user_inputs.include? 'USERNAME')
  end
end
