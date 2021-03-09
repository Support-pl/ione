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

RUBY_LIB_LOCATION = "/usr/lib/one/ruby"
ETC_LOCATION      = "/etc/one/"

$: << RUBY_LIB_LOCATION

require 'opennebula'
include OpenNebula

vm = VirtualMachine.new_with_id(vmid, Client.new)
vm.info!

u = User.new_with_id vm['UID'].to_i, Client.new
u.info!

exit 0 if u.groups.include? 0

balance = u['TEMPLATE/BALANCE'].to_f

require 'yaml'
require 'json'
require 'sequel'
require 'augeas'

work_file_dir  = File.dirname(ONED_CONF)
work_file_name = File.basename(ONED_CONF)

aug = Augeas.create(:no_modl_autoload => true,
                    :no_load          => true,
                    :root             => work_file_dir,
                    :loadpath         => ONED_CONF)

aug.clear_transforms
aug.transform(:lens => 'Oned.lns', :incl => work_file_name)
aug.context = "/files/#{work_file_name}"
aug.load

if aug.get('DB/BACKEND') != "\"mysql\"" then
  STDERR.puts "OneDB backend is not MySQL, exiting..."
  exit 1
end

ops = {}
ops[:host]     = aug.get('DB/SERVER')
ops[:user]     = aug.get('DB/USER')
ops[:password] = aug.get('DB/PASSWD')
ops[:database] = aug.get('DB/DB_NAME')

ops.each do |k, v|
  next if !v || !(v.is_a? String)

  ops[k] = v.chomp('"').reverse.chomp('"').reverse
end

ops.merge! adapter: :mysql2, encoding: 'utf8mb4'

$db = Sequel.connect(**ops)
conf = $db[:settings].as_hash(:name, :body)

vm.recover 3 if balance == 0 && u.groups.include?(conf['IAAS_GROUP_ID'].to_i)

capacity = JSON.parse(conf['CAPACITY_COST'])
vm_price = capacity['CPU_COST'].to_f * vm['//TEMPLATE/VCPU'].to_i + capacity['MEMORY_COST'].to_f * vm['//TEMPLATE/MEMORY'].to_i / 1000

if balance < vm_price * 86400 then
  puts "User balance isn't enough to deploy this VM, deleting..."
  vm.recover 3
else
  puts "User has enough balance, do whatever you want"
end
