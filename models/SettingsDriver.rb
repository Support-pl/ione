require 'sequel'

require $ione_conf['DataBase']['gem']
$DB = Sequel.connect({
        adapter: $ione_conf['DataBase']['adapter'].to_sym,
        user: $ione_conf['DataBase']['user'], password: $ione_conf['DataBase']['pass'],
        database: $ione_conf['DataBase']['database'], host: $ione_conf['DataBase']['host'],
        encoding: 'utf8mb4'   })

$DB.extension(:connection_validator)
$DB.pool.connection_validation_timeout = -1

begin
    $DB.create_table :settings do 
        String :name, size: 128, primary_key: true
        String :body, text: true, null: false
        String :description, text: true, null: true
    end

    required = [
        ['ALERT', "0.0", ""],
        ['CAPACITY_COST', "{\"CPU_COST\":\"0.0\",\"MEMORY_COST\":\"0.0\"}", ""],
        ['DISK_TYPES', "comma_separated_list_of_disk_types", ""],
        ['DISK_COSTS', "{\"disk_type\":\"price\"}", ""],
        ['IAAS_GROUP_ID', 'iaas_group_id', ""],
        ['NODES_DEFAULT', "{\"hypervisor_name\":\"host_id\"}", ""],
        ['PUBLIC_IP_COST', "0.0", ""],
        ['PUBLIC_NETWORK_DEFAULTS', "{\"NETWORK_ID\":\"network_id\"}", ""],
        ['PRIVATE_NETWORK_DEFAULTS', "{\"NETWORK_ID\":\"network_id\"}", ""],
        ['CURRENCY_MAIN', "€", ""]
    ]
    required.each do | record |
        $DB[:settings].insert(name: record[0], body: record[1], description: record[2])
    end
rescue
    puts "Table :settings already exists, skipping"
end

SETTINGS_TABLE = $DB[:settings]

def db_result answer
    answer.as_hash(:name, :body)
end

get '/settings' do
    begin
        r response: db_result(SETTINGS_TABLE)
    rescue => e
        r error: e.message, debug: e.class
    end
end

get '/settings/:key' do | key |
    begin
        r response: db_result(SETTINGS_TABLE.where(name:key))
    rescue => e
        r error: e.message
    end
end

post '/settings' do
    begin
        data = JSON.parse(@request_body)
        r response: SETTINGS_TABLE.insert(name: data['name'], body: data['body'])
    rescue => e
        r error: e.message
    end
end

post '/settings/:key' do | key |
    begin
        data = JSON.parse(@request_body)
        r response: SETTINGS_TABLE.where(name: key).update(name: key, body: data['body'])
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