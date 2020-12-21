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
    puts "User wasn't deleted, skipping"
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

$ione_conf = YAML.load_file("#{ETC_LOCATION}/ione.conf") # IONe configuration constants
require $ione_conf['DB']['adapter']
$db = Sequel.connect({
        adapter: $ione_conf['DB']['adapter'].to_sym,
        user: $ione_conf['DB']['user'], password: $ione_conf['DB']['pass'],
        database: $ione_conf['DB']['database'], host: $ione_conf['DB']['host']  })
conf = $db[:settings].as_hash(:name, :body)

id = user.id

unless user.groups.include? conf['IAAS_GROUP_ID'].to_i then
    puts "Not IaaS User, skipping..."
    exit 0
end

def pool id
    $db[:vm_pool].select(:oid).where(uid: id).exclude(state: 6).to_a
end

def vn_pool id
    $db[:network_pool].select(:oid).where(uid: id).to_a
end

until pool(id) == []
    pool(id).each do | vm |
        VirtualMachine.new_with_id(vm[:oid], Client.new).terminate(true)
    end
end

vn_pool(id).each do | vnet |
    vnet = VirtualNetwork.new_with_id(vnet[:oid], Client.new)
    vnet.info!

    if vnet['/VNET/TEMPLATE/TYPE'] == 'PRIVATE' then
        VirtualNetwork.new_with_id(JSON.parse(conf['PRIVATE_NETWORK_DEFAULTS'])['NETWORK_ID'], Client.new).add_ar(
            "AR = [\n" \
            "IP = \"#{vnet['/VNET/AR_POOL/AR/IP']}\",\n" \
            "SIZE = \"#{vnet['/VNET/AR_POOL/AR/SIZE']}\",\n" \
            "TYPE = \"#{vnet['/VNET/AR_POOL/AR/TYPE']}\",\n" \
            "VLAN_ID = \"#{vnet['/VNET/VLAN_ID']}\" ]"
        ) if vnet['VN_MAD'] == 'vcenter'
    end
    
    vnet.delete unless vnet.id == JSON.parse(conf['PRIVATE_NETWORK_DEFAULTS'])['NETWORK_ID'].to_i
end

puts "User##{id} Virtual Networks successfully cleaned up"