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

STARTUP_TIME = Time.now.to_f

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

CONF = YAML.load_file("#{ETC_LOCATION}/config.yml") # IONe configuration constants
require CONF['DataBase']['adapter']
$db = Sequel.connect({
        adapter: CONF['DataBase']['adapter'].to_sym,
        user: CONF['DataBase']['user'], password: CONF['DataBase']['pass'],
        database: CONF['DataBase']['database'], host: CONF['DataBase']['host']  })

id = ARGV.first

vm = VirtualMachine.new_with_id id, Client.new
vm.info!

begin
    if vm.to_hash['VM']['USER_TEMPLATE']['HOOK_VARS']['SET_COST'] != "TRUE" then
        raise
    end
rescue => exception
    puts "Attribute HOOK_VARS/SET_COST is FALSE or not set. Skipping..."
    exit 0
end

db = $db[:settings].as_hash(:name, :body)

costs = {}

costs.merge!(
    'CPU_COST' => JSON.parse(db['CAPACITY_COST'])['CPU_COST'] * vm['/VM/TEMPLATE/CPU'],
    'MEMORY_COST' => JSON.parse(db['CAPACITY_COST'])['MEMORY_COST'] * vm['/VM/TEMPLATE/MEMORY'] / 1024
)

JSON.parse db['CAPACITY_COST']

unless vm['/VM/TEMPLATE/DISK'].nil? then
    cost, disk_volume = JSON.parse(db['DISK_COSTS']), vm['/VM/TEMPLATE/DISK/SIZE'].to_f / 1024

    costs.merge!(
        'DISK_COST' => cost[vm['/VM/TEMPLATE/CONTEXT/DRIVE']].to_f * disk_volume
    )
end

unless vm['/VM/TEMPLATE/NIC'].nil? then
    cost, public_ip_count = db['PUBLIC_IP_COST'].to_f, 0
    
    nic = vm.to_hash['VM']['TEMPLATE']['NIC']
    if nic.class == Array then
        nic.each do | el |
            vnet = VirtualNetwork.new_with_id el['NETWORK_ID'], Client.new
            vnet.info!
            public_ip_count += vnet['/VNET/TEMPLATE/TYPE'] == 'PUBLIC' ? 1 : 0
        end
    elsif nic.class == Hash 
        vnet = VirtualNetwork.new_with_id nic['NETWORK_ID'], Client.new
        vnet.info!
        public_ip_count += vnet['/VNET/TEMPLATE/TYPE'] == 'PUBLIC' ? 1 : 0
    end

    costs.merge!(
        'PUBLIC_IP_COST' => cost * public_ip_count
    )
end

template =
    costs.inject("") do | result, el |
        result += "#{el.first} = \"#{el.last}\"\n"
    end

vm.update(template, true)

puts "Work time: #{(Time.now.to_f - STARTUP_TIME).round(6).to_s} sec"
