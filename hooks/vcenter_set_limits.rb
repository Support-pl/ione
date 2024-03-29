#!/usr/bin/env ruby

# -------------------------------------------------------------------------- #
# Copyright 2017-2021, IONe Cloud Project, Support.by                        #
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

RUBY_LIB_LOCATION = "/usr/lib/one/ruby"
ALPINE = ENV["ALPINE"] == "true"
if ALPINE then
  $: << ENV["IONE_LOCATION"]
else
  ETC_LOCATION = "/etc/one/"
  ONED_CONF    = ETC_LOCATION + '/oned.conf'
  $: << '/usr/lib/one/ione'
end

require "uri"
require "net/http"
require "yaml"
require "json"

require 'opennebula'
include OpenNebula

require 'core/*'
require 'service/objects/xml_element'
require 'service/objects/host'
require 'service/objects/vm'

client = ALPINE ? Client.new(ENV["ONE_CREDENTIALS"], ENV["ONE_ENDPOINT"]) : Client.new

xml = Nokogiri::XML(Base64::decode64(ARGV.first))
id = xml.xpath('//ID').text.to_i
vm = VirtualMachine.new_with_id(id, client)
vm.info!

if vm['/VM/USER_TEMPLATE/HYPERVISOR'].downcase == 'vcenter' then
  limits, spec = vm.getResourcesAllocationLimits, {}
  puts "Limits are configured as: #{limits}"

  host = vm.host.last
  key = IONe::Settings['VCENTER_CPU_LIMIT_FREQ_PER_CORE'][host].nil? ? 'default' : host
  cpu_lim = vm['/VM/TEMPLATE/VCPU'].to_i * IONe::Settings['VCENTER_CPU_LIMIT_FREQ_PER_CORE'][key]
  spec[:cpu] = cpu_lim if cpu_lim != limits[:cpu]

  if limits[:ram] != vm['/VM/TEMPLATE/MEMORY'].to_i then
    spec[:ram] = vm['/VM/TEMPLATE/MEMORY'].to_i
  end

  if limits[:iops] == -1 then
    spec[:iops] = IONe::Settings['VCENTER_DRIVES_IOPS'][vm['/VM/USER_TEMPLATE/DRIVE'] || 'default']
    spec[:iops] = -1 if spec[:iops].nil? || spec[:iops] == 0
  end

  puts "Generated following spec: #{spec}"
  _, e = vm.setResourcesAllocationLimits spec
  puts "Result: #{e}"
end

puts 'Successful set Limits up'
exit 0
