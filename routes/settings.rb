require 'mysql2'
require 'sequel'

# Get this values from /etc/oned.conf
$DB = Sequel.connect({
    adapter: :mysql2, user: 'root', password: 'opennebula', database: 'opennebula', host: 'localhost'  })

SETTINGS_TABLE = $DB[:settings]

def db_result answer
    answer.as_hash(:name, :body)
end

get '/settings' do
    begin
        r response: db_result(SETTINGS_TABLE)
    rescue => e
        r error: e.message
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