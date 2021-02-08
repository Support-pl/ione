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

require 'yaml'
require 'sequel'

$ione_conf = YAML.load_file("/etc/one/ione.conf") # IONe configuration constants

require $ione_conf['DB']['adapter']
$db = Sequel.connect({
        adapter: $ione_conf['DB']['adapter'].to_sym,
        user: $ione_conf['DB']['user'], password: $ione_conf['DB']['pass'],
        database: $ione_conf['DB']['database'], host: $ione_conf['DB']['host']  })

$db[:traffic_records].insert(
    vm: vmid, rx: "0", tx: "0", rx_last: "0", tx_last: "0", stime: Time.now.to_i, etime: Time.now.to_i
)