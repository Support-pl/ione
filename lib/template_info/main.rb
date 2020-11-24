class IONe
    # @!group Templates Info

    # Obtains the list of all available Templates(and filters by groupd_id if given)
    # @param [Fixnum] group_id - group if to filter by(optional)
    # @return [Array]
    def get_templates_list group_id = nil
        LOG_STAT()
        id = id_gen()
        tp_pool = TemplatePool.new(@client)
        tp_pool.info_all!
        tp_pool.inject([]) do | res, tp |
            res << {
                id: tp.id,
                name: tp.name,
                description: tp.to_hash['VMTEMPLATE']['TEMPLATE']['DESCRIPTION'],
                logo: tp.to_hash['VMTEMPLATE']['TEMPLATE']['LOGO'],
                uid: tp.to_hash['VMTEMPLATE']['UID'],
                gid: tp.to_hash['VMTEMPLATE']['GID'],
            } if group_id.nil? or group_id.to_i == tp.to_hash['VMTEMPLATE']['GID'].to_i
            res
        end
    end
    
    # @!endgroup
end