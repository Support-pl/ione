#!/usr/bin/env ruby
# -------------------------------------------------------------------------- #
# Copyright 2018, IONe Cloud Project, Support.by                             #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
# -------------------------------------------------------------------------- #

ONE_LOCATION = ENV["ONE_LOCATION"] if !defined?(ONE_LOCATION)

if !ONE_LOCATION
    RUBY_LIB_LOCATION = "/usr/lib/one/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = "/etc/one/" if !defined?(ETC_LOCATION)
else
    RUBY_LIB_LOCATION = ONE_LOCATION + "/lib/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = ONE_LOCATION + "/etc/" if !defined?(ETC_LOCATION)
end

$: << RUBY_LIB_LOCATION
require 'yaml'
require 'json'
require 'sequel'
require 'opennebula'
include OpenNebula

$ione_conf = YAML.load_file("#{ETC_LOCATION}/ione.conf") # IONe configuration constants
require $ione_conf['DataBase']['adapter']
$db = Sequel.connect({
        adapter: $ione_conf['DataBase']['adapter'].to_sym,
        user: $ione_conf['DataBase']['user'], password: $ione_conf['DataBase']['pass'],
        database: $ione_conf['DataBase']['database'], host: $ione_conf['DataBase']['host']  })
conf = $db[:settings].as_hash(:name, :body)

id = ARGV.first

user = User.new_with_id id, Client.new
user.info!

unless user.groups.include? conf['IAAS_GROUP_ID'].to_i then
    puts "Not IaaS User, skipping..."
    exit 0
end

vnet = VirtualNetwork.new_with_id(JSON.parse(conf['PRIVATE_NETWORK_DEFAULTS'])['NETWORK_ID'], Client.new)
vnet.info!
begin
    ar_pool = vnet.to_hash['VNET']['AR_POOL']['AR']
rescue
    puts ar_pool.inspect
    exit(-1)
end
ar_pool.select! do | ar |
    ar['USED_LEASES'] == "0"
end

ar = ar_pool.sample

if vnet['VN_MAD'] == 'vcenter' then
    user_vnet = vnet.clone
    user_vnet.allocate("
        NAME = \"user-#{user.id}-vnet\"
        BRIDGE = \"user-#{user.id}-vnet\"
        VCENTER_PORTGROUP_TYPE = \"Distributed Port Group\"
        VCENTER_SWITCH_NAME = \"#{vnet['/VNET/TEMPLATE/VCENTER_SWITCH_NAME']}\"
        VCENTER_SWITCH_NPORTS = \"#{vnet['/VNET/TEMPLATE/VCENTER_SWITCH_NPORTS']}\"
        VLAN_ID = \"#{ar['VLAN_ID']}\"
        VN_MAD = \"vcenter\"
        TYPE = \"PRIVATE\"
        VCENTER_ONE_HOST_ID = \"#{JSON.parse(conf['NODES_DEFAULT'])['VCENTER']}\"", conf['DEFAULT_CLUSTER'].to_i)

    user_vnet.add_ar("AR = [
        IP = \"#{ar['IP']}\",
        SIZE = \"#{ar['SIZE']}\",
        TYPE = \"#{ar['TYPE']}\" ]")

    vnet.rm_ar ar['AR_ID']
else
    user_vnet = vnet.reserve("user-#{user.id}-vnet", ar['SIZE'], ar['AR_ID'], nil, nil)
    user_vnet = VirtualNetwork.new_with_id(user_vnet, Client.new)
end

user_vnet.chown(user.id, conf['IAAS_GROUP_ID'].to_i)
puts "Virtual Network for User##{user.id} successfuly created with id #{user_vnet.id}"