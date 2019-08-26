require 'zmqjsonrpc'
require 'yaml'
require 'json'
require 'ipaddr'
require 'sequel'

STARTUP_TIME = Time.now().to_i # IONe server start time

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

PLUGIN_CONFIGURATION_FILE = ETC_LOCATION + "/sunstone-plugins.yaml"
LOGOS_CONFIGURATION_FILE = ETC_LOCATION + "/sunstone-logos.yaml"

SUNSTONE_ROOT_DIR = File.dirname(__FILE__)

$: << RUBY_LIB_LOCATION
$: << RUBY_LIB_LOCATION+'/cloud'
$: << SUNSTONE_ROOT_DIR
$: << SUNSTONE_ROOT_DIR+'/models'

DISPLAY_NAME_XPATH = 'TEMPLATE/SUNSTONE/DISPLAY_NAME'
TABLE_ORDER_XPATH = 'TEMPLATE/SUNSTONE/TABLE_ORDER'
DEFAULT_VIEW_XPATH = 'TEMPLATE/SUNSTONE/DEFAULT_VIEW'
GROUP_ADMIN_DEFAULT_VIEW_XPATH = 'TEMPLATE/SUNSTONE/GROUP_ADMIN_DEFAULT_VIEW'
TABLE_DEFAULT_PAGE_LENGTH_XPATH = 'TEMPLATE/SUNSTONE/TABLE_DEFAULT_PAGE_LENGTH'
LANG_XPATH = 'TEMPLATE/SUNSTONE/LANG'

require 'rubygems'
require 'sinatra'
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


begin
    $conf = YAML.load_file(CONFIGURATION_FILE)
rescue Exception => e
    STDERR.puts "Error parsing config file #{CONFIGURATION_FILE}: #{e.message}"
    exit 1
end

if $conf[:one_xmlrpc_timeout]
    ENV['ONE_XMLRPC_TIMEOUT'] = $conf[:one_xmlrpc_timeout].to_s unless ENV['ONE_XMLRPC_TIMEOUT']
end

$conf[:debug_level] ||= 3

# Set Sunstone Session Timeout
$conf[:session_expire_time] ||= 3600

# Set the TMPDIR environment variable for uploaded images
ENV['TMPDIR']=$conf[:tmpdir] if $conf[:tmpdir]

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

DEBUG_LIB = true
begin
    require 'ione/server/ione.rb'
rescue => e
    puts e.message, e.backtrace
end