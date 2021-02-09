#!/usr/bin/env ruby
# -------------------------------------------------------------------------- #
# Copyright 2020, IONe Cloud Project, Support.by                             #
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

require 'base64'
require 'nokogiri'

xml = Nokogiri::XML(Base64::decode64(ARGV.first))
unless xml.xpath("/CALL_INFO/RESULT").text.to_i == 1 then
    puts "User wasn't allocated, skipping"
    exit 0
end

RUBY_LIB_LOCATION = "/usr/lib/one/ruby"
ETC_LOCATION      = "/etc/one/"

$: << RUBY_LIB_LOCATION

require 'opennebula'
include OpenNebula
user = User.new xml.xpath('//EXTRA/USER'), Client.new
user.info!

require 'yaml'
require 'json'
require 'sequel'
require 'augeas'

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

ops.merge! adapter: :mysql2,  encoding: 'utf8mb4'

$db = Sequel.connect(**ops)

conf = $db[:settings].as_hash(:name, :body)

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

bridge = vnet['//BRIDGE_PATTERN']
if bridge.nil? then
    bridge = "user-#{user.id}-vnet"
else
    bridge = bridge.gsub('<%VLAN_ID%>', ar['VLAN_ID'])
end

if vnet['VN_MAD'] == 'vcenter' then
    user_vnet = vnet.clone
    user_vnet.allocate("
        NAME = \"user-#{user.id}-vnet\"
        BRIDGE = \"#{bridge}\"
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
clusters = vnet.to_hash['VNET']['CLUSTERS']['ID']
clusters = [ clusters ] if clusters.class != Array
for c in clusters do
    Cluster.new_with_id(c.to_i, Client.new).addvnet(user_vnet.id)
end

puts "Virtual Network for User##{user.id} successfuly created with id #{user_vnet.id}"
