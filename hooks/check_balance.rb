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

require 'base64'
require 'nokogiri'

xml = Nokogiri::XML(Base64::decode64(ARGV[1]))
unless xml.xpath("/CALL_INFO/RESULT").text.to_i == 1 then
  puts "VM wasn't allocated, skipping"
  exit 0
end

vmid = nil
if ARGV.first == 'vm' then
  vmid = xml.xpath('//ID').text.to_i
elsif ARGV.first == 'tmpl' then
  vmid = xml.xpath('/CALL_INFO/PARAMETERS/PARAMETER[TYPE="OUT"][POSITION=2]/VALUE').text.to_i
else
  puts "IDK what to do🤷‍♂️"
  exit 0
end

ALPINE = ENV["ALPINE"] == "true"
if ALPINE then
  $: << ENV["IONE_LOCATION"]
else
  ETC_LOCATION = "/etc/one/"
  ONED_CONF    = ETC_LOCATION + '/oned.conf'
  $: << '/usr/lib/one/ione'
end

require 'opennebula'
include OpenNebula

client = ALPINE ? Client.new(ENV["ONE_CREDENTIALS"], ENV["ONE_ENDPOINT"]) : Client.new

vm = VirtualMachine.new_with_id(vmid, client)
vm.info!

u = User.new_with_id vm['UID'].to_i, client
u.info!

exit 0 if u.groups.include? 0

balance = u['TEMPLATE/BALANCE'].to_f

require 'yaml'
require 'json'

require 'core/*'

vm.recover 3 if balance == 0 && u.groups.include?(IONe::Settings['IAAS_GROUP_ID'])

capacity = IONe::Settings['CAPACITY_COST']
vm_price = capacity['CPU_COST'].to_f * vm['//TEMPLATE/VCPU'].to_i + capacity['MEMORY_COST'].to_f * vm['//TEMPLATE/MEMORY'].to_i / 1000

if balance < vm_price * 86400 && u.groups.include?(IONe::Settings['IAAS_GROUP_ID']) then
  puts "User balance isn't enough to deploy this VM, deleting..."
  vm.recover 3
else
  puts "User has enough balance, do whatever you want"
end
