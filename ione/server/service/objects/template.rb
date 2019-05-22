# OpenNebula::Template class
class OpenNebula::Template
    # Checks given template OS type by User Input
    # @return [Boolean]
    def win?
        self.info!
        self.to_hash['VMTEMPLATE']['TEMPLATE']['USER_INPUTS'].include? 'USERNAME'
    end
end
