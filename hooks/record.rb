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
require 'sequel'
require 'opennebula'
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

state, lcm_state = vm.state_str, vm.lcm_state_str

state = 
if ["PENDING", "HOLD"].include? state then
    'pnd'
elsif ["BOOT", "RUNNING"].include? lcm_state then
    'on'
elsif ["STOPPED", "SUSPENDED", "DONE", "POWEROFF"].include? state then
    'off'
else
    'pnd'
end

$db[:records].insert(:id => id, :state => state, :time => Time.now.to_i)

puts "Success. State: #{state}, VM State:#{vm.state_str}"
# create table records(id int not null, state varchar(10) not null, time int)