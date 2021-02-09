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

# ROOT = ENV['IONEROOT'] # IONe root path
# require "#{ROOT}/debug_lib.rb"
ONE_LOCATION = ENV["ONE_LOCATION"] if !defined?(ONE_LOCATION)

if !ONE_LOCATION
    RUBY_LIB_LOCATION = "/usr/lib/one/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = "/etc/one/" if !defined?(ETC_LOCATION)
else
    RUBY_LIB_LOCATION = ONE_LOCATION + "/lib/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = ONE_LOCATION + "/etc/" if !defined?(ETC_LOCATION)
end

$: << RUBY_LIB_LOCATION
require 'opennebula'
include OpenNebula

require "uri"
require "net/http"
require "yaml"

client = Client.new
one_auth = client.instance_variable_get("@one_auth").split(':')

id = ARGV.first.to_i
vm = VirtualMachine.new_with_id(id, client)
vm.info!
puts "States are: [#{ARGV[1]}, #{ARGV[2]}] -> [#{vm.state} -- #{vm.state_str}, #{vm.lcm_state} -- #{vm.lcm_state_str}]"
if ARGV[1, 2] != ["ACTIVE", "BOOT"] then
    puts "VM started not from PENDING state, skipping..."
    exit 0
end

api = URI("http://localhost:8009/ione/get_vm_host")
req = Net::HTTP::Post.new(api)
req.body = JSON.generate params: [id, true]
req.basic_auth *one_auth
r = Net::HTTP.start(api.hostname, api.port, use_ssl: false) do | http |
    http.request(req)
end
res = JSON.parse r.body
host = res["response"].last.to_i

if vm['/VM/USER_TEMPLATE/HYPERVISOR'].downcase == 'vcenter' then

    iops = YAML.load_file("#{ETC_LOCATION}/ione.conf")['vCenter']['default']['drives-iops']

    api = URI("http://localhost:8009/ione/SetVMResourcesLimits")
    req = Net::HTTP::Post.new(api)
    req.body = JSON.generate params: [
        id, host, 
        {
            'cpu' => vm['/VM/TEMPLATE/VCPU'].to_i,
            'ram' => vm['/VM/TEMPLATE/MEMORY'].to_i,
            'iops' => iops[vm['/VM/USER_TEMPLATE/DRIVE'] || 'default']
        }
    ]
    req.basic_auth *one_auth
    r = Net::HTTP.start(api.hostname, api.port, use_ssl: false) do | http |
        http.request(req)
    end
end

puts 'Successful set Limits up'
exit 0