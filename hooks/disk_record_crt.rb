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
  puts "Disk wasn't attached/detached, skipping"
  exit 0
end

RUBY_LIB_LOCATION = "/usr/lib/one/ruby"
ETC_LOCATION      = "/etc/one/"

$: << RUBY_LIB_LOCATION
$: << '/usr/lib/one/ione'

vm = xml.xpath("//PARAMETER[TYPE='IN' and POSITION=2]/VALUE").text

require 'opennebula'
include OpenNebula

vm = VirtualMachine.new_with_id vm, Client.new
vm.info!

ONED_CONF = ETC_LOCATION + '/oned.conf'

require 'core/*'
require 'json'

disk = vm.to_hash['VM']['TEMPLATE']['DISK'].sort_by { | d | d['DISK_ID'].to_i }.last

if IONe::Settings['BACKUP_IMAGE_CONF'].values.include? disk['IMAGE_ID'] then
  $db[:disk_records].insert vm: vm.id, id: disk['DISK_ID'], crt: Time.now.to_i, type: "backup", size: disk['SIZE'], img: disk['IMAGE_ID']
else
  $db[:disk_records].insert vm: vm.id, id: disk['DISK_ID'], crt: Time.now.to_i, type: "system", size: disk['SIZE']
end
