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

$ione_conf = YAML.load_file("#{ETC_LOCATION}/ione.conf") # IONe configuration constants
require $ione_conf['DB']['adapter']
$db = Sequel.connect({
        adapter: $ione_conf['DB']['adapter'].to_sym,
        user: $ione_conf['DB']['user'], password: $ione_conf['DB']['pass'],
        database: $ione_conf['DB']['database'], host: $ione_conf['DB']['host']  })

class AR < Sequel::Model(:ars); end

AR.create do | r |
    r.vnid  = vnet.id
    r.arid  = ARGV.last == 'crt' ? 0 : -1
    r.time  = Time.now.to_i
    r.state = ARGV.last
end