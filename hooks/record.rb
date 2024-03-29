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

ALPINE = ENV["ALPINE"] == "true"
if ALPINE then
  $: << ENV["IONE_LOCATION"]
else
  ETC_LOCATION = "/etc/one/"
  ONED_CONF    = ETC_LOCATION + '/oned.conf'
  $: << '/usr/lib/one/ione'
end

require 'yaml'
require 'base64'
require 'nokogiri'
require 'core/*'

vm_template = Nokogiri::XML(Base64::decode64(ARGV.first))
id = vm_template.xpath("//ID").text.to_i

puts "Writing new record for VM##{id}"

state = ARGV[1]

$db[:records].insert(id: id, state: state, time: Time.now.to_i)

puts "Success. State: #{state}"
