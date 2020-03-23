class IONe
   def reserve_public_ip params = {}, trace = ["Reserve_Public_IP method called:#{__LINE__}"]
    params = {
        n: 1,
        u: 721
    }

    conf = @db[:settings].as_hash(:name, :body)
    vnet = onblock(:vn, JSON.parse(conf['PUBLIC_NETWORK_DEFAULTS'])['NETWORK_ID'])
    vnet.info!

    u = onblock(:u, params[:u])
    u.info!

    if (uvnet = u.vns(@db).select{|v| v.type == 'PUBLIC'}.first) then
        uvnet = uvnet.id
    end

    uvnet = vnet.reserve(
        uvnet ? nil : "user-#{params[:u]}-pub-vnet", params[:n], nil, nil, uvnet
    )
    onblock(:vn, uvnet).chown(u.id, u.groups.first)

    r = Record.create do | r |
        r.id    = uvnet
        r.state = 'res'
        r.time  = Time.now.to_i
        r.type  = 'vn'
        r.meta  = JSON.generate(AR_ID: 0)
    end

    return true
   end
end

IONe.new($client, $db).reserve_public_ip()
Record.where(type:'vn').to_a