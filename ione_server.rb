#!/usr/bin/env ruby

# Server start-up time
STARTUP_TIME = Time.now().to_i # IONe server start time
INIT_IONE = true
ALPINE = ENV["ALPINE"] == 'true'

if ALPINE then
  require 'rake'
  Rake.load_rakefile('Rakefile')
  Rake::Task['hooks_tp'].invoke
end

# OpenNebula Ruby files location
ONE_LOCATION = ENV["ONE_LOCATION"]

if !ONE_LOCATION
  # OpenNebula(and IONe) Logs location
  LOG_LOCATION = "/var/log/one"
  # OpenNebula home
  VAR_LOCATION = "/var/lib/one"
  # OpenNebula configs location
  ETC_LOCATION = "/etc/one"
end
if ALPINE
  LOG_LOCATION ||= ENV["LOG_LOCATION"]
end

# IONe source location
ROOT_DIR = File.dirname(__FILE__)

if ALPINE then
  $: << ROOT_DIR
  $: << ROOT_DIR + '/models'
else
  $: << '/usr/lib/one/ione'
  $: << '/usr/lib/one/ione/models'
end

######################
# Required libraries #
######################
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

#################
# Configuration #
#################

begin
  conf_path = ALPINE ? "/ione/sys/ione.conf" : "#{ETC_LOCATION}/ione.conf"
  $ione_conf = YAML.load_file(conf_path) # IONe configuration constants
rescue => e
  STDERR.puts "Error parsing config file #{conf_path}: #{e.message}"
  exit 1
end

use Rack::Deflater

require 'ipaddr'

puts 'Getting path to the server'
ROOT = ROOT_DIR # IONe root path
LOG_ROOT = LOG_LOCATION # IONe logs path

# Shows if current IONe Sunstone process was started by systemd(first time so). True or False
MAIN_IONE = Process.ppid == 1

CONF = $ione_conf # for sure

puts 'Including log-library'
require "#{ROOT}/service/log.rb"
include IONeLoggerKit

puts 'Setting up Environment(OpenNebula API)'
###########################
# Setting up Environment  #
###########################

# Loading DB Credentials and connecting DB

ONED_CONF = ETC_LOCATION + '/oned.conf' unless ALPINE

require 'core/*'

$db.extension(:connection_validator)
$db.pool.connection_validation_timeout = -1

puts 'Checking service version'
# IONe version
VERSION = File.read("#{ROOT}/meta/version.txt")

require "opennebula"
include OpenNebula
###########################################
# OpenNebula credentials
CREDENTIALS = ALPINE ? ENV["ONE_CREDENTIALS"] : File.read(VAR_LOCATION + "/.one/one_auth").chomp
# XML_RPC endpoint where OpenNebula is listening
ENDPOINT = ALPINE ? ENV["ONE_ENDPOINT"] : "http://localhost:#{$oned_conf.get('PORT')}/RPC2"
$client = Client.new(CREDENTIALS, ENDPOINT) # oneadmin auth-client

puts 'Including on_helper funcs'
require "#{ROOT}/service/on_helper.rb"
include ONeHelper
puts 'Including showback'
require "#{ROOT}/service/showback.rb"
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

  # Will call object method if smth like vm_poweroff(1) called
  def method_missing method, *args, &block
    obj, method = method.to_s.split('_')
    if ONeHelper::ON_INSTANCES.keys.include? obj.to_sym then
      onblock(obj.to_sym, args[0]).send(method, self)
    else
      super
    end
  end
end

ione_drivers = %w(AnsibleDriver AzureDriver IONeKernel VLANManager)
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
      $ione_conf.merge!(YAML.safe_load(File.read("#{ROOT}/modules/#{mod}/config.yml"))) if File.exist?("#{ROOT}/modules/#{mod}/config.yml")
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
RPC_LOGGER.info "Preparing to start up server"
RPC_LOGGER.info "Condition is !defined?(DEBUG_LIB)(#{!defined?(DEBUG_LIB)}) && MAIN_IONE(#{MAIN_IONE}) => #{!defined?(DEBUG_LIB) && MAIN_IONE}"

#
# IONe API based on http
#
puts "Binding on #{ALPINE ? '0.0.0.0' : 'localhost'}:8009"
set :bind, ALPINE ? '0.0.0.0' : 'localhost'
set :port, 8009

before do
  if request.request_method == 'OPTIONS' then
    halt 200, {}, ""
  end
  begin
    unless ['GET', 'DELETE'].include? request.request_method then
      @request_body = request.body.read
      if @request_body.empty? then
        @request_hash = { 'params' => [] }
      else
        @request_hash = JSON.parse @request_body
        @request_hash['params'] = [] if @request_hash['params'].nil?
      end
    end
    if (request.env['HTTP_AUTHORIZATION'].nil? or request.env['HTTP_AUTHORIZATION'].empty?) and request.params["ws"] != 'true' then
      halt 401, { 'Allow' => "*" }, "No Credentials given"
    end

    if request.params["ws"] == 'true' then
      @auth = Base64.decode64 request.params["auth"]
    else
      @auth = Base64.decode64 request.env['HTTP_AUTHORIZATION'].split(' ').last
    end

    env[:one_client] = @client   = Client.new(@auth, ENDPOINT)
    env[:one_user]   = @one_user = User.new_with_id(-1, @client)
    rc = @one_user.info!
    if OpenNebula.is_error?(rc)
      halt 401, { 'Allow' => "*" }, "False Credentials given"
    end
    RPC_LOGGER.info "Authorized #{@one_user.name} as #{@one_user.admin? ? "" : "NOT "}Admin"
  rescue => e
    RPC_LOGGER.info "Exception #{e.message}"
    RPC_LOGGER.info "Backtrace #{e.backtrace.inspect}"
    halt 200, { 'Content-Type' => 'application/json', 'Allow' => "*" }, { response: e.message }.to_json
  end
end

puts "Allowing CORS"
# Sinatra :after helper allowing Cors by adding needed headers
after do
  response.headers['Allow'] = "*"
  response.headers['Access-Control-Allow-Origin'] = "*"
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
    RPC_LOGGER.info "IONeAPI calls proxy method #{method}(#{@request_hash['params'].collect { |p| p.inspect }.join(", ")})"
    r = IONe.new(@client, $db).send(method, *@request_hash['params'])
  rescue => e
    r = e.message
    backtrace = e.backtrace
  ensure
    r = { error: r.message } if OpenNebula.is_error? r
  end
  err = defined?(backtrace) && !backtrace.nil?
  RPC_LOGGER.info "IONeAPI sends response #{r.inspect}"
  RPC_LOGGER.info "Backtrace #{backtrace.inspect}" if err
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
  begin
    RPC_LOGGER.info "ONeAPI calls proxy object method one.#{object}.#{method}(#{@request_hash['params'].collect { |p| p.inspect }.join(", ")})"
    r = onblock(object.to_sym, @request_hash['oid'], @client).send(method.to_s << excl.to_s, *@request_hash['params'])
  rescue => e
    r = e.message
    backtrace = e.backtrace
  ensure
    r = { error: r.message } if OpenNebula.is_error? r
  end
  err = defined?(backtrace) && !backtrace.nil?
  RPC_LOGGER.info "ONeAPI sends response #{r.inspect}"
  RPC_LOGGER.info "Backtrace #{backtrace.inspect}" if err
  json response: r
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
  begin
    RPC_LOGGER.info "ONeAPI calls proxy pool method one.#{object}.pool.#{method}(#{@request_hash['params'].collect { |p| p.inspect }.join(", ")})"
    r =
      (
        @request_hash['uid'].nil? ?
          ON_INSTANCE_POOLS[object.to_sym].new(@client) :
          ON_INSTANCE_POOLS[object.to_sym].new(@client, @request_hash['uid'])
      ).send(method.to_s << excl.to_s, *@request_hash['params'])
  rescue => e
    r = e.message
    backtrace = e.backtrace
  ensure
    r = { error: r.message } if OpenNebula.is_error? r
  end
  err = defined?(backtrace) && !backtrace.nil?
  RPC_LOGGER.info "ONeAPI sends response #{r.inspect}"
  RPC_LOGGER.info "Backtrace #{backtrace.inspect}" if err
  json response: r
end

puts 'Including extra endpoints'
LOG_COLOR 'Including extra endpoints:', 'none', 'green', 'bold'
Dir["#{ROOT}/routes/*.rb"].each do |file|
  mod = file.split('/').last.split('.').first
  puts "\tIncluding #{mod}"
  require file
  LOG_COLOR "\t - #{mod} -- included", 'none', 'green', 'itself'
end

puts 'Enpoints are registered, starting up done'
RPC_LOGGER.info "Endpoints are registered, starting up done"
