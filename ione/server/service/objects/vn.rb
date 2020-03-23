class OpenNebula::VirtualNetwork
    def type
        info! || self['TEMPLATE/TYPE']
    end
end