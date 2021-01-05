begin
    $db.create_table :settings do 
        String  :name, size: 128, primary_key: true
        String  :body, text: true, null: false
        String  :description, text: true, null: true
        Integer :access_level, null: false, default: 1
        String  :type, null: false
    end

    required = [
        ['ALERT', "0.0", "Balance, when user will be alerted", 0, "num"],
        ['CAPACITY_COST', "{\"CPU_COST\":\"0.0\",\"MEMORY_COST\":\"0.0\"}", "VM Capacity resources costs", 1, "object"],
        ['DISK_TYPES', "HDD,SSD,NVMe", "Comma-separated list of existing disk types", 1, "list"],
        ['DISK_COSTS', "{\"disk_type\":\"price\"}", "Costs of different disk types", 1, "object"],
        ['IAAS_GROUP_ID', 'iaas_group_id', "IaaS(VDC) Users group ID", 1, "num"],
        ['NODES_DEFAULT', "{\"hypervisor_name\":\"host_id\"}", "Default nodes for different hypervisors", 1, "object"],
        ['PUBLIC_IP_COST', "0.0", "Public IP Address cost", 0, "num"],
        ['PUBLIC_NETWORK_DEFAULTS', "{\"NETWORK_ID\":\"network_id\"}", "Default Public Network Pool ID", 1, "object"],
        ['PRIVATE_NETWORK_DEFAULTS', "{\"NETWORK_ID\":\"network_id\"}", "Default Private Network Pool ID", 1, "object"],
        ['CURRENCY_MAIN', "€", "Currency", 0, "str"],
        ['TRAFFIC_COST', "0.0", "Cost per 1 kByte traffic", 1, "num"]
    ]
    required.each do | record |
        $db[:settings].insert(name: record[0], body: record[1], description: record[2], access_level: record[3], type: record[4])
    end
rescue
    puts "Table :settings already exists, skipping"
end

SETTINGS_TABLE = $db[:settings]

get '/settings' do
    begin
        r response: SETTINGS_TABLE.to_a
    rescue => e
        r error: e.message, debug: e.class
    end
end

get '/settings/:key' do | key |
    begin
        r response: SETTINGS_TABLE.where(name:key).to_a.last
    rescue => e
        r error: e.message
    end
end

post '/settings' do
    begin
        data = JSON.parse(@request_body)
        r response: SETTINGS_TABLE.insert(**data.to_sym!)
    rescue => e
        r error: e.message
    end
end

post '/settings/:key' do | key |
    begin
        data = JSON.parse(@request_body)
        data = data.to_sym!
        r response: SETTINGS_TABLE.where(name: key).update(name: key, **data)
    rescue => e
        r error: e.message
    end
end

delete '/settings/:key' do | key |
    begin
        r response: SETTINGS_TABLE.where(name: key).delete
    rescue => e
        r error: e.message
    end
end