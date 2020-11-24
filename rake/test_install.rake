require 'pathname'
require 'yaml'

task :test_install_gems do 
    require "colorize"
    require 'net/http'
    require 'sequel'
end

def passed
    puts "--- " + "Passed".green
end
def fail msg
    puts msg.red
    exit
end
def warn msg
    puts msg.yellow
end

desc "Check if IONe config exists and correct"
task :test_config_exists do
    puts "Checking if config exists"
    unless Pathname.new("/etc/one/ione.conf").exist? then
        fail "ione.conf does not exist on /etc/one/. You can get it from repo."
    end
    passed

    puts "Checking if config can be parsed"
    begin
        YAML.load_file("/etc/one/ione.conf")
    rescue => e
        fail "Failed to parse ione.conf, got: #{e.message}"
    end
    passed

end

desc "Check if IONe is configured"
task :test_configured do
    conf = YAML.load_file("/etc/one/ione.conf")

    puts "Checking if DB is configured"
    unless conf['DB'].class == Hash then
        fail "DB config is empty"
    end
    passed

    conf = conf['DB']

    puts "Checking if DB connector is installed"
    gem  = conf['gem']
    begin
        require gem
    rescue => e
        fail "Failed to load DB connect gem(#{gem}), got: #{e.message}"
    end
    passed

    puts "Checking if DB config is not default"
    if conf['user'] == 'user' || conf['pass'] == 'secret' then
        warn "!!! WARNING !!! DB Credentials are probably unset"
    end
    if [conf['user'], conf['pass'], conf['host'], conf['database'], conf['gem'], conf['adapter']].include? nil then
        fail "DB config has nil values"
    end
    passed

    puts "Checking if IONe can establish connection to database"
    begin
        db = Sequel.connect({
            adapter: conf['adapter'].to_sym,
            user: conf['user'], password: conf['pass'],
            database: conf['database'], host: conf['host'],
            encoding: 'utf8mb4' })
    rescue => e
        fail "Can't connect to database, got: #{e.message}"
    end
    passed

    puts "Checking if settings table exists"
    unless db.table_exists? :settings then
        fail "Table :settings doesn't exist"
    end
    passed
end

desc "Check if IONe UI is up"
task :test_api_root do
    puts "Testing '/'"
    api = URI("http://localhost:8009/")
    begin
        r = Net::HTTP.get_response(api)
    rescue => e
        fail "Unable to get response from '/', got: #{r.code} #{e.message}" unless r.code == 401 
    end
    unless r.is_a? Net::HTTPSuccess then
        fail "Unable to get response from '/', got: #{r.code} #{r.body}" unless r.code == 401 
    end
    passed

    puts "Can get response from 'Test'"
    api = URI("http://localhost:8009/ione/Test")
    begin
        r = Net::HTTP.post(api, nil)
    rescue => e
        fail "Unable to get response from '/ione/Test', got: #{e.message}" 
    end
    if r.code != "200" then
        fail "Got #{r.code} response from Test, should be 200."
    end
    passed
end

desc "Check if IONe is installed and running"
task :test_install => [:test_install_gems, :test_config_exists, :test_configured, :test_api_root] do

end