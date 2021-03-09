#!/usr/bin/env ruby
# -------------------------------------------------------------------------- #
# Copyright 2020, IONe Cloud Project, Support.by                             #
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
  puts "VNet wasn't allocated/deleted, skipping"
  exit 0
end

RUBY_LIB_LOCATION = "/usr/lib/one/ruby"
ETC_LOCATION      = "/etc/one/"

$: << RUBY_LIB_LOCATION
require 'opennebula'
include OpenNebula

vnet = VirtualNetwork.new xml.xpath('//EXTRA/VNET'), Client.new
vnet.info!

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
class AR < Sequel::Model(:ars); end

AR.create do | r |
  r.vnid = vnet.id
  r.arid  = ARGV.last == 'crt' ? 0 : -1
  r.time  = Time.now.to_i
  r.state = ARGV.last
end
