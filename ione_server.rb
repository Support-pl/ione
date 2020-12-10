#!/usr/bin/env ruby
ONE_LOCATION = ENV["ONE_LOCATION"]

if !ONE_LOCATION
    LOG_LOCATION = "/var/log/one"
    VAR_LOCATION = "/var/lib/one"
    ETC_LOCATION = "/etc/one"
    SHARE_LOCATION = "/usr/share/one"
    RUBY_LIB_LOCATION = "/usr/lib/one/ruby"
else
    VAR_LOCATION = ONE_LOCATION + "/var"
    LOG_LOCATION = ONE_LOCATION + "/var"
    ETC_LOCATION = ONE_LOCATION + "/etc"
    SHARE_LOCATION = ONE_LOCATION + "/share"
    RUBY_LIB_LOCATION = ONE_LOCATION+"/lib/ruby"
end

SUNSTONE_AUTH             = VAR_LOCATION + "/.one/sunstone_auth"
SUNSTONE_LOG              = LOG_LOCATION + "/sunstone.log"
CONFIGURATION_FILE        = ETC_LOCATION + "/sunstone-server.conf"

ROOT_DIR = File.dirname(__FILE__)

$: << RUBY_LIB_LOCATION
$: << RUBY_LIB_LOCATION+'/cloud'
$: << ROOT_DIR
$: << ROOT_DIR+'/models'

##############################################################################
# Required libraries
##############################################################################
require 'rubygems'
require 'sinatra'
require "sinatra/json"
require 'erb'
require 'yaml'
require 'securerandom'
require 'tmpdir'
require 'fileutils'
require 'base64'
require 'rexml/document'
require 'uri'
require 'open3'

require 'CloudAuth'
require 'SunstoneServer'
require 'SunstoneViews'

##############################################################################
# Configuration
##############################################################################

begin
    $conf = YAML.load_file(CONFIGURATION_FILE)
rescue Exception => e
    STDERR.puts "Error parsing config file #{CONFIGURATION_FILE}: #{e.message}"
    exit 1
end
begin
    $ione_conf = YAML.load_file("#{ETC_LOCATION}/ione.conf") # IONe configuration constants
rescue Exception => e
    STDERR.puts "Error parsing config file #{ETC_LOCATION}/ione.conf: #{e.message}"
    exit 1
end

##############################################################################
# Enable logger
##############################################################################
include CloudLogger
logger=enable_logging(SUNSTONE_LOG, $conf[:debug_level].to_i)

begin
    ENV["ONE_CIPHER_AUTH"] = SUNSTONE_AUTH
    $cloud_auth = CloudAuth.new($conf, logger)
rescue => e
    logger.error {
        "Error initializing authentication system" }
    logger.error { e.message }
    exit(-1)
end

set :cloud_auth, $cloud_auth

use Rack::Deflater

require 'ipaddr'
require 'sequel'
require 'logger'

STARTUP_TIME = Time.now().to_i # IONe server start time

puts 'Getting path to the server'
ROOT = ROOT_DIR # IONe root path
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

require $ione_conf['DB']['adapter']
$db = Sequel.connect({
        adapter: $ione_conf['DB']['adapter'].to_sym,
        user: $ione_conf['DB']['user'], password: $ione_conf['DB']['pass'],
        database: $ione_conf['DB']['database'], host: $ione_conf['DB']['host'],
        encoding: 'utf8mb4'   })

$db.extension(:connection_validator)
$db.pool.connection_validation_timeout = -1

require "SettingsDriver"

# Settings Table Model
# @see https://github.com/ione-cloud/ione-sunstone/blob/55a9efd68681829624809b4895a49d750d6e6c34/models/SettingsDriver.rb#L13-L37 Settings Model Definition
class Settings < Sequel::Model(:settings); end

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

ione_drivers = %w( AnsibleDriver AzureDriver ShowbackDriver IONeCustomActions)
ione_drivers.each do | driver |
    begin
        require driver
    rescue LoadError => e
        puts "Driver #{driver} was not included: #{e.message}"
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
            Thread.new { require "#{ROOT}/scripts/#{script}/main.rb" }
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
# Logger instance for rpc calls
RPC_LOGGER = Logger.new(rpc_log_file)

puts 'Pre-init job ended, starting up server'
RPC_LOGGER.debug "Preparing to start up server"
RPC_LOGGER.debug "Condition is !defined?(DEBUG_LIB)(#{!defined?(DEBUG_LIB)}) && MAIN_IONE(#{MAIN_IONE}) => #{!defined?(DEBUG_LIB) && MAIN_IONE}"

#
# IONe API based on http
#
puts "Binding on localhost:8009"
set :bind, '0.0.0.0'
set :port, 8009

before do
    if request.request_method == 'OPTIONS' then
        halt 200, {
            'Allow' => "HEAD,GET,PUT,POST,DELETE,OPTIONS",
            "Access-Control-Allow-Headers" => "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
        }, ""
    end
    begin
        unless request.request_method == 'GET' then
            @request_body = request.body.read
            @request_hash = JSON.parse @request_body
        end
        if request.env['HTTP_AUTHORIZATION'].nil? or request.env['HTTP_AUTHORIZATION'].empty? then
            halt 401, { 'Allow' => "*" }, "No Credentials given"
        end
        @auth = Base64.decode64 request.env['HTTP_AUTHORIZATION'].split(' ').last
        @client = Client.new(@auth)
        @one_user = User.new_with_id(-1, @client)
        rc = @one_user.info!
        if OpenNebula.is_error?(rc)
            halt 401, { 'Allow' => "*" }, "False Credentials given"
        end
    rescue => e
        RPC_LOGGER.debug "Exception #{e.message}"
        RPC_LOGGER.debug "Backtrace #{e.backtrace.inspect}"
        halt 200, { 'Content-Type' => 'application/json', 'Allow' => "*" }, { response: e.message }.to_json
    end
end

puts "Allowing CORS"
# Sinatra :after helper allowing Cors by adding needed headers
after do
    response.headers['Allow'] = "*" unless response.headers['Allow']
    response.headers['Access-Control-Allow-Origin'] = "*" unless response.headers['Access-Control-Allow-Origin']
    response.headers['Access-Control-Allow-Methods'] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
    response.headers['Access-Control-Allow-Headers'] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Authorization"
end

puts "Registering IONe methods"
# Endpoint to invoke IONe methods
# @example Request:
#    POST /ione/Test
#        Headers:
#            Authorization: Basic base64_encoded_credentials
#        Body:
#        {
#            "params": [ "PING" ]
#        }
#    Response:
#        200 - { "response": "PONG" }
# @see IONe#Test
post '/ione/:method' do | method |
    begin
        RPC_LOGGER.debug "IONeAPI calls proxy method #{method}(#{@request_hash['params'].collect {|p| p.inspect}.join(", ")})"
        r = IONe.new(@client, $db).send(method, *@request_hash['params'])
    rescue => e
        r = e.message
        backtrace = e.backtrace
    end
    RPC_LOGGER.debug "IONeAPI sends response #{r.inspect}"
    RPC_LOGGER.debug "Backtrace #{backtrace.inspect}" if defined? backtrace and !backtrace.nil?
    json response: r
end

puts "Registering ONe methods"
# Endpoint to invoke ONe Instances methods
# @example Request:
#    POST /one.vm.name
#        Headers:
#            Authorization: Basic base64_encoded_credentials
#        Body:
#        {
#            "oid": 777,
#            "params": [ ]
#        }
#    Response:
#        200 - { "response": "one-vm-777-name" }
# @see ONeHelper#onblock-instance_method
post %r{/one\.(\w+)\.(\w+)(\!|\=)?} do | object, method, excl |
    json(response:
        onblock(object.to_sym, @request_hash['oid'], @client).send(method.to_s << excl.to_s, *@request_hash['params'])
    )
end

puts "Registering ONe Pool methods"
# Endpoint to invoke ONe Pool methods
# @example Request:
#    POST /one.vm.pool.monitoring
#        Headers:
#            Authorization: Basic base64_encoded_credentials
#        Body:
#        {
#            "uid": "0"  // optional
#            "params": [ ]
#        }
#    Response:
#        200 - { "response": [...] }
# @see ONeHelper#onblock-instance_method
post %r{/one\.(\w+)\.pool\.(\w+)(\!|\=)?} do | object, method, excl |
    json(response:
        (
            @request_hash['uid'].nil? ? 
                ON_INSTANCE_POOLS[object.to_sym].new(@client) :
                ON_INSTANCE_POOLS[object.to_sym].new(@client, @request_hash['uid'])
        ).send(method.to_s << excl.to_s, *@request_hash['params'])
    )
end