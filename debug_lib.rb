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

begin
    require 'ione/server/ione.rb'
rescue => e
    puts e.message, e.backtrace
end