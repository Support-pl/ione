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

ETC_LOCATION = "/etc/one/"
ONED_CONF = ETC_LOCATION + '/oned.conf'

require 'yaml'
require 'sequel'
require 'base64'
require 'nokogiri'
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

ops.merge! adapter: :mysql2,  encoding: 'utf8mb4'

$db = Sequel.connect(**ops)

vm_template = Nokogiri::XML(Base64::decode64(ARGV.first))
id = vm_template.xpath("//ID").text.to_i

puts "Writing new record for VM##{id}"

state = ARGV[1]

$db[:records].insert(id: id, state: state, time: Time.now.to_i)

puts "Success. State: #{state}"
# create table records(id int not null, state varchar(10) not null, time int)