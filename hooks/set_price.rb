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

nk_encoding = nil

if RUBY_VERSION =~ /^1.9/
    Encoding.default_external = Encoding::UTF_8
    Encoding.default_internal = Encoding::UTF_8
    nk_encoding = "UTF-8"
end

NOKOGIRI_ENCODING = nk_encoding

ONE_LOCATION = ENV["ONE_LOCATION"] if !defined?(ONE_LOCATION)

if !ONE_LOCATION
    RUBY_LIB_LOCATION = "/usr/lib/one/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = "/etc/one/" if !defined?(ETC_LOCATION)
else
    RUBY_LIB_LOCATION = ONE_LOCATION + "/lib/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = ONE_LOCATION + "/etc/" if !defined?(ETC_LOCATION)
end

$: << RUBY_LIB_LOCATION
$: << RUBY_LIB_LOCATION+'/onedb'

require 'yaml'
require 'json'
require 'sequel'
require 'opennebula'
require 'onedb'
require 'onedb_live'
include OpenNebula

$ione_conf = YAML.load_file("#{ETC_LOCATION}/ione.conf") # IONe configuration constants
require $ione_conf['DB']['adapter']
$db = Sequel.connect({
        adapter: $ione_conf['DB']['adapter'].to_sym,
        user: $ione_conf['DB']['user'], password: $ione_conf['DB']['pass'],
        database: $ione_conf['DB']['DB'], host: $ione_conf['DB']['host']  })

id = ARGV.first

vm = VirtualMachine.new_with_id id, Client.new
vm.info!

begin
    if vm.to_hash['VM']['USER_TEMPLATE']['HOOK_VARS']['SET_COST'] != "TRUE" then
        raise
    end
rescue
    puts "Attribute HOOK_VARS/SET_COST is FALSE or not set. Skipping..."
    exit 0
end

db = $db[:settings].as_hash(:name, :body)

costs = {}

if %(vcenter kvm).include?(vm['USER_TEMPLATE/HYPERVISOR'].downcase) then
    costs.merge!(
        'CPU_COST' => JSON.parse(db['CAPACITY_COST'])['CPU_COST'].to_f,
        'MEMORY_COST' => JSON.parse(db['CAPACITY_COST'])['MEMORY_COST'].to_f,
        'DISK_COST' => JSON.parse(db['DISK_COSTS'])[vm['/VM/TEMPLATE/CONTEXT/DRIVE']].to_f,
        'PUBLIC_IP_COST' => db['PUBLIC_IP_COST'].to_f
    )
elsif vm['USER_TEMPLATE/HYPERVISOR'].downcase == 'azure' then
    sku = JSON.parse(
        JSON.parse( db['AZURE_SKUS'] )[ vm['USER_TEMPLATE/PUBLIC_CLOUD/INSTANCE_TYPE'] ]
    )

    costs.merge!(
        'CPU_COST' => sku['PRICE'].to_f / 2,
        'MEMORY_COST' => sku['PRICE'].to_f / 2,
        'DISK_COST' => JSON.parse(db['AZURE_DISK_COSTS'])[vm['USER_TEMPLATE/DRIVE']].to_f
    )
end

template =
    costs.inject("") do | result, el |
        result += "#{el.first} = \"#{el.last}\"\n"
    end

vm.update(template, true)

action = OneDBLive.new
costs.each do | key, value |
    action.change_body('vm', "/VM/TEMPLATE/#{key}", value.to_s, {:id => vm.id})
end

puts "Work time: #{(Time.now.to_f - STARTUP_TIME).round(6).to_s} sec"
