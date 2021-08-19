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

    vnet = onblock(:vn, IONe::Settings['PUBLIC_NETWORK_DEFAULTS']['IAAS'], @client)
    vnet.info!

    u = onblock(:u, params[:u], @client)
    u.info!

    if (uvnet = u.vns(@db).select { |v| v.type == 'PUBLIC' }.first) then
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

        clusters = vnet.to_hash['VNET']['CLUSTERS']['ID']
        clusters = [clusters] if clusters.class != Array
        for c in clusters do
          onblock(:c, c).addvnet(uvnet)
        end
      end
      if OpenNebula.is_error?(uvnet) && uvnet.errno == 2048 then
        return { error: "No free addresses left" }
      end

      ar = onblock(:vn, uvnet, @client).ar_pool.last
      AR.create do | r |
        r.vnid  = uvnet
        r.arid  = ar['AR_ID']
        r.stime = Time.now.to_i
        r.owner = params[:u]
      end
    end

    vn = onblock(:vn, uvnet, $client)
    vn.chown(u.id, u.groups.first)
    vn.chmod(1, 1, 1, 0, 0, 0, 0, 0, 0)
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

    vn = onblock(:vn, params[:vn], @client)
    vn.info!

    if vn.rm_ar(params[:ar]).nil? then
      AR.where(vnid: params[:vn], arid: params[:ar], owner: vn['//UID']).update(etime: Time.now.to_i)
      true
    else
      false
    end
  end

  # Returns all @client User vnets
  # @return [Array<Hash>]
  def get_user_vnets
    onblock(:u, -1, @client) do | u |
      u.info!
      u.vns(@db).map { |vn| vn.to_hash }
    end
  end
end
