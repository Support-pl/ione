begin
require 'azure_driver'

post '/vnet/:id/register_azure_ip' do | id |
    begin
        vnet = onblock(:vn, id)
        vnet.info!
        
        rg_name = vnet["/VNET/TEMPLATE/RESOURCE_GROUP"]
        location = vnet["/VNET/TEMPLATE/LOCATION"]
        host = vnet["/VNET/TEMPLATE/AZURE_HOST_ID"]
        az_drv = AzureDriver::Client.new(host)
        time = Time.now.to_i.to_s
        name = rg_name + "-#{time}-ip"

        ip = az_drv.mk_public_ip(rg_name, name, location)
        
        vnet.add_ar(
            'AR=[' \
            "   IP=\"#{ip.ip_address}\"," \
            '   SIZE="1",' \
            "   STIME=\"#{Time.now.to_i.to_s}\"," \
            "   AZ_NAME=\"#{name}\"," \
            '   TYPE="IP4" ]'
        )

        r response: nil
    rescue => e
        r error: e.message, backtrace: e.backtrace  
    end
end

post '/vnet/:id/unregister_azure_ip' do | id |
    begin
        data = JSON.parse(request.body.read)
        vnet = onblock(:vn, id)
        vnet.info!
        name = data['name']
        
        rg_name = vnet["/VNET/TEMPLATE/RESOURCE_GROUP"]
        host = vnet["/VNET/TEMPLATE/AZURE_HOST_ID"]
        az_drv = AzureDriver::Client.new(host)

        vnet.rm_ar(data['ar_id'])
        az_drv.rm_public_ip(rg_name, name)

        r response: nil
    rescue => e
        r error: e.message, backtrace: e.backtrace  
    end
end
rescue LoadError => e
    puts "No Azure Driver found, skipping"
end