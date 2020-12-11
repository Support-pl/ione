require 'pathname'
require 'yaml'

task :test_install_gems do 
    require 'colorize'
    require 'net/http'
    require 'sequel'
    require 'base64'
    require 'json'
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

task :load_installed_env do
    @one_auth  = File.read('/var/lib/one/.one/one_auth').chomp
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

    @uris = [URI("http://localhost:8009/")]

    r = nil
    until ['y', 'n'].include? r do
        print "Do you have DNS configured? (y/n) "
        r = gets.chomp.downcase
    end
    if r == 'y' then
        r = uri = nil
        until ['y', 'n'].include? r do
            print "Enter your domain name: "
            uri = gets.chomp.downcase
            print "Is '#{uri}' correct? (y/n) "
            r = gets.chomp.downcase
        end
        if r == 'y' then
            @uris << URI("http://#{uri}/")
            @uris << URI("https://#{uri}/")
        end
    end

    def fail msg
        puts msg.red
    end

    for uri in @uris do
    begin
        puts "Testing #{uri.to_s}"
        puts "-------------------"
        puts "Testing '/'"
        api = uri
        begin
            req = Net::HTTP::Get.new(api)
            req.basic_auth *@one_auth.split(':')
            r = Net::HTTP.start(api.hostname, api.port, use_ssl: api.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE) do | http |
                http.request(req)
            end
        rescue => e
            fail "Unable to get response from '/', got: #{r.code} #{e.message}" unless r.code == 401 
        end
        if uri.scheme == 'http' && r.code == "301" then
            passed
            next
        end
        unless r.code == "404" then
            fail "Unable to get 404 from '/', got: #{r.code} #{r.body}"
        end
        passed

        puts "Can get response from 'Test'"
        api = uri + "/ione/Test"
        begin
            req = Net::HTTP::Post.new(api)
            req.basic_auth *@one_auth.split(':')
            r = Net::HTTP.start(api.hostname, api.port, use_ssl: api.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE) do | http |
                http.request(req)
            end
        rescue => e
            fail "Unable to get response from '/ione/Test', got: #{e.message}" 
        end
        if r.code != "200" then
            fail "Got #{r.code} response from Test, should be 200."
        end
        passed

        puts "Can get PONG from PING"
        api = uri + "/ione/Test"
        begin
            req = Net::HTTP::Post.new(api)
            req.body = JSON.generate params: ['PING']
            req.basic_auth *@one_auth.split(':')
            r = Net::HTTP.start(api.hostname, api.port, use_ssl: api.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE) do | http |
                http.request(req)
            end
        rescue => e
            fail "Unable to get response from '/ione/Test', got: #{e.message}" 
        end
        if r.code != "200" then
            fail "Got #{r.code} response from Test, should be 200."
        end
        begin
            res = JSON.parse r.body
            r = res['response']
            fail "Wrong response schema: #{res}" if r.nil?
            fail "Expected PONG, got: #{r}" unless r == 'PONG'
        rescue JSON::ParserError
            fail "Got un-parseable string: #{r.body}"
        end
        passed
    rescue => e
        puts e.message
    end
    end
end

desc "Check if IONe is installed and running"
task :test_install => [:test_install_gems, :load_installed_env, :test_config_exists, :test_configured, :test_api_root] do

end