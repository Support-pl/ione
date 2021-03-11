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
require 'service/records/disk_records'

disks = vm.to_hash['VM']['TEMPLATE']['DISK']
disks = [ disks ] if disks.class == Hash
disks.map { | disk | disk['DISK_ID'].to_i }

DiskRecord.where(vm: vm.id, del: nil).all.select { | d | !disks.include? d[:id] }.each do | rec |
  rec.update(del: Time.now.to_i)
end
