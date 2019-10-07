require 'zmqjsonrpc'
require 'yaml'
require 'ipaddr'
require 'sequel'
require 'logger'
require 'securerandom'

STARTUP_TIME = Time.now().to_i # IONe server start time

puts 'Getting path to the server'
ROOT = SUNSTONE_ROOT_DIR + '/ione/server' # IONe root path
LOG_ROOT = LOG_LOCATION # IONe logs path

# Shows if current IONe Sunstone process was started by systemd(first time so). True or False
MAIN_IONE = Process.ppid == 1

$ione_conf = YAML.load_file("#{ETC_LOCATION}/ione.conf") if !defined?($ione_conf)
CONF = $ione_conf # for sure

puts 'Including log-library'
require "#{ROOT}/service/log.rb"
include IONeLoggerKit

puts 'Checking service version'
VERSION = File.read("#{ROOT}/meta/version.txt") # IONe version
USERS_GROUP = $ione_conf['OpenNebula']['users-group'] # OpenNebula users group
TRIAL_SUSPEND_DELAY = $ione_conf['Server']['trial-suspend-delay'] # Trial VMs suspend delay

USERS_VMS_SSH_PORT = $ione_conf['OpenNebula']['users-vms-ssh-port'] # Default SSH port at OpenNebula Virtual Machines 

puts 'Setting up Environment(OpenNebula API)'
###########################################
# Setting up Environment                   #
###########################################

require "opennebula"
include OpenNebula
###########################################
# OpenNebula credentials
CREDENTIALS = File.read(VAR_LOCATION + "/.one/one_auth").chomp #$ione_conf['OpenNebula']['credentials']
# XML_RPC endpoint where OpenNebula is listening
ENDPOINT = $ione_conf['OpenNebula']['endpoint']
$client = Client.new(CREDENTIALS, ENDPOINT) # oneadmin auth-client

require $ione_conf['DataBase']['adapter']
$db = Sequel.connect({
        adapter: $ione_conf['DataBase']['adapter'].to_sym,
        user: $ione_conf['DataBase']['user'], password: $ione_conf['DataBase']['pass'],
        database: $ione_conf['DataBase']['database'], host: $ione_conf['DataBase']['host'],
        encoding: 'utf8mb4'   })

$db.extension(:connection_validator)
$db.pool.connection_validation_timeout = -1

puts 'Including on_helper funcs'
require "#{ROOT}/service/on_helper.rb"
include ONeHelper
puts 'Including Deferable module'
require "#{ROOT}/service/defer.rb"

LOG(
"\n" +
"       ################################################################\n".light_green.bold +
"       ##                                                            ##\n".light_green.bold +
"       ##".light_green.bold + "       " + "I".red.bold + "ntegrated " + "O".red.bold + "pen" + "Ne".red.bold + "bula Cloud  " +
                                    "v#{VERSION.chomp}".cyan.underline + "#{" " if VERSION.split(' ').last == 'stable'}        " + "##\n".light_green.bold +
"       ##                                                            ##\n".light_green.bold +
"       ################################################################\n".light_green.bold +
"\n", 'none', false
)


puts 'Generating "at_exit" directive'
at_exit do
    begin
        LOG_COLOR("Server was stopped. Uptime: #{fmt_time(Time.now.to_i - STARTUP_TIME)}", "")
        LOG "", "", false
        LOG("       ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++", "", false)
    rescue => e
        LOG_DEBUG e.message
    end
end

# Main App class. All methods, which must be available as JSON-RPC methods, should be defined in this class
class IONe
    include Deferable
    # IONe initializer, stores auth-client and version
    # @param [OpenNebula::Client] client 
    def initialize(client, db)
        @client = client
        @db = db
        @version = VERSION
    end
end

puts 'Including Libs'
LOG_COLOR 'Including Libs:', 'none', 'green', 'bold'
begin
    $ione_conf['Include'].each do | lib |
        puts "\tIncluding #{lib}"    
        begin
            require "#{ROOT}/lib/#{lib}/main.rb"
            LOG_COLOR "\t - #{lib} -- included", 'none', 'green', 'itself'
        rescue => e
            LOG_COLOR "Library \"#{lib}\" was not included | Error: #{e.message}", 'LibraryController'
            puts "Library \"#{lib}\" was not included | Error: #{e.message}"
        end
    end if $ione_conf['Include'].class == Array
rescue => e
    LOG_ERROR "LibraryController fatal error | #{e}", 'LibraryController', 'red', 'underline'
    puts "\tLibraryController fatal error | #{e}"
end

puts 'Including Modules'
LOG_COLOR 'Including Modules:', 'none', 'green', 'bold'
begin
    $ione_conf['Modules'].each do | mod |
        puts "\tIncluding #{mod}"    
        begin
            $ione_conf.merge!(YAML.load(File.read("#{ROOT}/modules/#{mod}/config.yml"))) if File.exist?("#{ROOT}/modules/#{mod}/config.yml")
            require "#{ROOT}/modules/#{mod}/main.rb"
            LOG_COLOR "\t - #{mod} -- included", 'none', 'green', 'itself'
        rescue => e
            LOG_COLOR "Module \"#{mod}\" was not included | Error: #{e.message}", 'ModuleController'
            puts "Module \"#{mod}\" was not included | Error: #{e.message}"
        end
    end if $ione_conf['Modules'].class == Array
rescue => e
    LOG_ERROR "ModuleController fatal error | #{e}", 'ModuleController', 'red', 'underline'
    puts "\tModuleController fatal error | #{e}"
end

puts 'Including Scripts'
LOG_COLOR 'Starting scripts:', 'none', 'green', 'bold'
begin
    $ione_conf['Scripts'].each do | script |
        puts "\tIncluding #{script}"
        begin
            Thread.new do
                require "#{ROOT}/scripts/#{script}/main.rb"
            end
                LOG_COLOR "\t - #{script} -- initialized", 'none', 'green', 'itself'
            rescue => e
                LOG_COLOR "Script \"#{script}\" was not started | Error: #{e.message}", 'ScriptController', 'green', 'itself'
                puts "\tScript \"#{script}\" was not started | Error: #{e.message}"
        end
    end if $ione_conf['Scripts'].class == Array
rescue => e
    LOG_ERROR "ScriptsController fatal error | #{e}", 'ScriptController', 'red', 'underline'
    puts "ScriptsController fatal error | #{e}"
end if MAIN_IONE

puts 'Making IONe methods deferable'
class IONe
    self.instance_methods(false).each do | method |
        deferable method
    end
end

$methods = IONe.instance_methods(false).map { | method | method.to_s }

rpc_log_file = "#{LOG_ROOT}/rpc.log"
`touch #{rpc_log_file}` unless File.exist? rpc_log_file
RPC_LOGGER = Logger.new(rpc_log_file)

LOG "Initializing JSON-RPC Server..."
puts 'Initializing JSON_RPC server and logic handler'
server = ZmqJsonRpc::Server.new(IONe.new($client, $db), "tcp://*:#{$ione_conf['Server']['listen-port']}", RPC_LOGGER)
LOG_COLOR "Server initialized", 'none', 'green'

puts 'Pre-init job ended, starting up server'
if !defined?(DEBUG_LIB) && MAIN_IONE then
    Thread.new do
        begin
            server.server_loop # Server start
        rescue => e
            LOG_ERROR "Server isn't started: #{e.message}\nBacktrace:#{e.backtrace}"
            puts "Server isn't started: #{e.message}\nBacktrace:#{e.backtrace}"
        end
    end

    IONeAPIServerThread = Thread.new do
        require 'pry-remote'
        class IONeAPIServer < Sinatra::Base
            set :bind, '0.0.0.0'
            set :port, 8009

            before do
                @request_body = request.body.read
            end

            get '/' do
                'Hello, World! via IONe Web API'
            end
            post '/ione/:method' do | method |
                begin
                    args = JSON.parse(@request_body)
                    u = User.new_with_id(-1, Client.new(args['auth']))
                    rc = u.info!
                    if OpenNebula.is_error?(rc)
                        raise "False Credentials given"
                    end
                    RPC_LOGGER.debug "IONeAPI calls proxy method #{method}(#{args['params'].collect {|p| p.inspect}.join(", ")})"
                    r = IONe.new(Client.new(params['auth']), $db).send(method, *args['params'])
                rescue => e
                    r = e.message
                    backtrace = e.backtrace
                end
                RPC_LOGGER.debug "IONeAPI sends response #{r.inspect}"
                RPC_LOGGER.debug "Backtrace #{backtrace.inspect}" if defined? backtrace
                JSON.pretty_generate response: r
            end
            get %r{one\.(\w+)\.(\w+)} do
                JSON.pretty_generate params[:captures]
            end
        end

        RPC_LOGGER.debug "Starting up IONeAPI Server on port 8009"
        begin
            run IONeAPIServer.run!
        rescue StandardError => e
            RPC_LOGGER.debug e.message
        end
    end

    at_exit do
        IONeAPIServerThread.kill
    end
end