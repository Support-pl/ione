require 'pathname'
require 'yaml'

task :test_install_deps do
  require 'colorize'
  require 'net/http'
  require 'sequel'
  require 'json'
  require 'augeas'
end

def passed
  puts "--- " + "Passed".green
end

def failed msg
  puts msg.red
  exit
end

def warn msg
  puts msg.yellow
end

task :load_installed_env do
  @one_auth = File.read('/var/lib/one/.one/one_auth').chomp
end

desc "Check if IONe config exists and correct"
task :test_config_exists do
  puts "Checking if config exists"
  unless Pathname.new("/etc/one/ione.conf").exist? then
    failed "ione.conf does not exist on /etc/one/. You can get it from repo."
  end

  passed

  puts "Checking if config can be parsed"
  begin
    YAML.load_file("/etc/one/ione.conf")
  rescue => e
    failed "Failed to parse ione.conf, got: #{e.message}"
  end
  passed
end

desc "Check if IONe is configured"
task :test_configured do
  puts "Checking if IONe can establish connection to database"
  begin
    ONED_CONF = '/etc/one/oned.conf'
    work_file_dir  = File.dirname(ONED_CONF)
    work_file_name = File.basename(ONED_CONF)

    aug = Augeas.create(:no_modl_autoload => true,
                        :no_load          => true,
                        :root             => work_file_dir,
                        :loadpath         => ONED_CONF)

    aug.clear_transforms
    aug.transform(:lens => 'Oned.lns', :incl => work_file_name)
    aug.context = "/files/#{work_file_name}"
    aug.load

    if aug.get('DB/BACKEND') != "\"mysql\"" then
      STDERR.puts "OneDB backend is not MySQL, exiting..."
      exit 1
    end

    ops = {}
    ops[:host]     = aug.get('DB/SERVER')
    ops[:user]     = aug.get('DB/USER')
    ops[:password] = aug.get('DB/PASSWD')
    ops[:database] = aug.get('DB/DB_NAME')

    ops.each do |k, v|
      next if !v || !(v.is_a? String)

      ops[k] = v.chomp('"').reverse.chomp('"').reverse
    end

    ops.merge! adapter: :mysql2, encoding: 'utf8mb4'

    db = Sequel.connect(**ops)
  rescue => e
    failed "Can't connect to database, got: #{e.message}"
  end
  passed

  puts "Checking if settings table exists"
  unless db.table_exists? :settings then
    failed "Table :settings doesn't exist"
  end

  passed
end

desc "Check if IONe UI is up"
task :test_api_root do
  @uris = [URI("http://localhost:8009/")]

  r = nil
  until ['y', 'n'].include? r do
    print "Do you have DNS configured? (y/n) "
    r = STDIN.gets.strip.downcase
  end
  if r == 'y' then
    r = uri = nil
    until ['y', 'n'].include? r do
      print "Enter your domain name: "
      uri = STDIN.gets.strip.downcase
      print "Is '#{uri}' correct? (y/n) "
      r = STDIN.gets.strip.downcase
    end
    if r == 'y' then
      @uris << URI("http://ione-api.#{uri}/")
      @uris << URI("https://ione-api.#{uri}/")
    end
  end

  puts

  for uri in @uris do
    begin
      puts "Testing #{uri}"
      puts "-------------------"
      puts "Testing '/'"
      api = uri
      begin
        req = Net::HTTP::Get.new(api)
        req.basic_auth(*@one_auth.split(':'))
        r = Net::HTTP.start(api.hostname, api.port, use_ssl: api.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE) do | http |
          http.request(req)
        end
      rescue => e
        failed "Unable to get response from '/', got: #{r.code} #{e.message}" unless r.code == 401
      end
      if uri.scheme == 'http' && r.code == "301" then
        passed
        next
      end
      unless r.code == "404" then
        failed "Unable to get 404 from '/', got: #{r.code} #{r.body}"
      end

      passed

      puts "Can get response from 'Test'"
      api = uri + "/ione/Test"
      begin
        req = Net::HTTP::Post.new(api)
        req.basic_auth(*@one_auth.split(':'))
        r = Net::HTTP.start(api.hostname, api.port, use_ssl: api.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE) do | http |
          http.request(req)
        end
      rescue => e
        failed "Unable to get response from '/ione/Test', got: #{e.message}"
      end
      if r.code != "200" then
        failed "Got #{r.code} response from Test, should be 200."
      end

      passed

      puts "Can get PONG from PING"
      api = uri + "/ione/Test"
      begin
        req = Net::HTTP::Post.new(api)
        req.body = JSON.generate params: ['PING']
        req.basic_auth(*@one_auth.split(':'))
        r = Net::HTTP.start(api.hostname, api.port, use_ssl: api.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE) do | http |
          http.request(req)
        end
      rescue => e
        failed "Unable to get response from '/ione/Test', got: #{e.message}"
      end
      if r.code != "200" then
        failed "Got #{r.code} response from Test, should be 200."
      end

      begin
        res = JSON.parse r.body
        r = res['response']
        failed "Wrong response schema: #{res}" if r.nil?
        failed "Expected PONG, got: #{r}" unless r == 'PONG'
      rescue JSON::ParserError
        failed "Got un-parseable string: #{r.body}"
      end
      passed
    rescue => e
      puts e.message
    end
    puts
  end
end

desc "Check if IONe is installed and running"
task :test_install => [:test_install_deps, :load_installed_env, :test_config_exists, :test_configured, :test_api_root] do
end
