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
require 'base64'
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

template = ARGV.first

user    = User.new(Nokogiri.parse(Base64.decode64(template)), Client.new)
id      = user.to_hash['document']['USER']['ID']

unless user.to_hash['document']['USER']['GROUPS']['ID'] == conf['IAAS_GROUP_ID'] then
    puts "Not IaaS User, skipping..."
    exit 0
end

def pool id
    $db[:vm_pool].select(:oid).where(:uid => id).exclude(:state => 6).to_a
end

until pool(id) == []
    pool(id).each do | vm |
        VirtualMachine.new_with_id(vm[:oid], Client.new).terminate(true)
    end
end

vnet_pool = VirtualNetworkPool.new Client.new
vnet_pool.info_all!

vnet_pool.each do | vnet |
    vnet.info!

    if vnet['/VNET/UID'].to_i == id.to_i && user.to_hash['document']['USER']['GROUPS']['ID'] == vnet['/VNET/GID'] then
    
        VirtualNetwork.new_with_id(JSON.parse(conf['PRIVATE_NETWORK_DEFAULTS'])['NETWORK_ID'], Client.new).add_ar(
            "AR = [\n" \
            "IP = \"#{vnet['/VNET/AR_POOL/AR/IP']}\",\n" \
            "SIZE = \"#{vnet['/VNET/AR_POOL/AR/SIZE']}\",\n" \
            "TYPE = \"#{vnet['/VNET/AR_POOL/AR/TYPE']}\",\n" \
            "VLAN_ID = \"#{vnet['/VNET/VLAN_ID']}\" ]"
        )
    
        vnet.delete unless vnet.id == JSON.parse(conf['PRIVATE_NETWORK_DEFAULTS'])['NETWORK_ID']
    end
end

puts "User##{id} Virtual Networks successfully cleaned up"