#!/usr/bin/env ruby

# -------------------------------------------------------------------------- #
# Copyright 2021, IONe Cloud Project, Support.by                             #
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

require 'yaml'

begin
  if YAML.load_file('/var/lib/one/remotes/etc/vmm/vcenter/vcenterrc')[:memory_dumps] then
    puts "memory_dumps: true => nothing to do, exiting"
    exit 0
  end
rescue => e
  puts "Can't load vcenterrc config, error: #{e.message}\nExiting..."
  exit 0
end

RUBY_LIB_LOCATION = "/usr/lib/one/ruby"
ETC_LOCATION      = "/etc/one/"
ONED_CONF         = ETC_LOCATION + "oned.conf"

$: << '/usr/lib/one/ione'
$: << RUBY_LIB_LOCATION
$: << RUBY_LIB_LOCATION + '/onedb'

require 'base64'
require 'json'
require 'nokogiri'
require "uri"
require "net/http"

require 'opennebula'
require 'onedb'
require 'onedb_live'
include OpenNebula

client = Client.new
one_auth = client.instance_variable_get("@one_auth").split(':')

xml = Nokogiri::XML(Base64::decode64(ARGV.first))
id = xml.xpath('//ID').text.to_i

vm = VirtualMachine.new_with_id(id, client)
vm.info!

puts "#{vm.state_str} -> #{vm.lcm_state_str}"

if ![0, 3].include? vm.state then
  puts "Not ACTIVE, skipping..."
  exit 0
elsif vm.state == 0 then
  puts "Waiting for state to become ACTIVE - RUNNING"
  3600.times do | t |
    vm.info!
    break if vm.lcm_state == 3

    if t == 3599 then
      puts "Timeout, exiting..."
      exit 0
    elsif vm.state != 0 || (vm.state == 3 && vm.lcm_state != 3) then
      puts "State isn't INIT and not RUNNING, but #{vm.state_str} - #{vm.lcm_state_str}, exiting..."
      exit 0
    end
    sleep 1
  end
end

api = URI("http://localhost:8009/one.vm.vcenter_powerState")
req = Net::HTTP::Post.new(api)
req.body = JSON.generate oid: id
req.basic_auth(*one_auth)
r = Net::HTTP.start(api.hostname, api.port, use_ssl: false) do | http |
  http.request(req)
end
res = JSON.parse r.body
state = res["response"]

if state != 'poweredOff' then
  puts "State isn't poweredOff, but #{state}, skipping..."
  exit 0
end

puts "Force changing state to POWEROFF"
OneDBLive::NOKOGIRI_ENCODING = 'UTF-8'
action = OneDBLive.new
action.change_body('vm', "/VM/STATE", 8, { :id => vm.id })
action.change_body('vm', "/VM/LCM_STATE", 0, { :id => vm.id })

puts "Done."
