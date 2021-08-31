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

xml = Nokogiri::XML(Base64::decode64(ARGV.first))
unless xml.xpath("/CALL_INFO/RESULT").text.to_i == 1 then
  puts "User wasn't deleted, skipping"
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

user = User.new xml.xpath('//EXTRA/USER'), client

require 'yaml'
require 'core/*'

id = user.id

if id == 0 then
  puts "oneadmin user, skipping..."
  exit 0
end

unless user.groups.include? IONe::Settings['IAAS_GROUP_ID'] then
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
    VirtualMachine.new_with_id(vm[:oid], client).terminate(true)
  end
end

vn_pool(id).each do | vnet |
  vnet = VirtualNetwork.new_with_id(vnet[:oid], client)
  vnet.delete
end

puts "User##{id} Resources are successfully cleaned up"
