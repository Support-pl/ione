class IONe

    #
    # Reserves Public IP or IPs to user private netpool
    #
    # @param [Hash] params
    # @option params [Integer] n - number of addresses to reserve
    # @option params [Integer] u - user id
    #
    # @return [Integer]
    #
    def reserve_public_ip params

        params.to_sym!

        conf = @db[:settings].as_hash(:name, :body)
        vnet = onblock(:vn, JSON.parse(conf['PUBLIC_NETWORK_DEFAULTS'])['NETWORK_ID'], @client)
        vnet.info!

        u = onblock(:u, params[:u], @client)
        u.info!

        if (uvnet = u.vns(@db).select{|v| v.type == 'PUBLIC'}.first) then
            uvnet = uvnet.id
        end

        params[:n].times do
            if uvnet then
                uvnet = vnet.reserve(nil, 1, nil, nil, uvnet)
            else
                uvnet = vnet.reserve("user-#{params[:u]}-pub-vnet", 1, nil, nil, uvnet)
                
                onblock(:vn, uvnet, @client) do | vn |
                    vn.update('TYPE="PUBLIC"', true)
                end
            end
        end

        vn = onblock(:vn, uvnet, @client)
        vn.chown(u.id, u.groups.first)
        ar = vn.ar_pool.sort_by{|o| o['AR_ID']}.last

        AR.create do | r |
            r.vnid  = vn.id
            r.arid  = ar['AR_ID']
            r.time  = Time.now.to_i
            r.state = 'crt'
            r.owner = params[:u]
        end

        return vn.id
    end
    #
    # Releases Public IP back to supernet-pool. Repeats OpenNebula::VirtualNetwork#rm_ar method, but with creating Record in :records storage
    #
    # @param [Hash] params
    # @option params [Integer] vn - Virtual Network ID
    # @option params [Integer] ar - Address Range ID
    #
    # @return [TrueClass]
    #
    def release_public_ip params

        params.to_sym!

        vn = onblock(:vn, params[:vn])
        vn.info!

        if vn.rm_ar(params[:ar]).nil? then
            AR.create do | r |
                r.vnid  = params[:vn]
                r.arid  = params[:ar]
                r.time  = Time.now.to_i
                r.state = 'del'
                r.owner = vn['//UID']
            end
            true
        else
            false
        end
    end

    # Returns all @client User vnets
    # @return [Array<Hash>]
    def get_user_vnets
        r = VirtualNetworkPool.new(@client, -1).get_hash['VNET_POOL']
        r.empty? ? [] : r['VNET']
    end
end