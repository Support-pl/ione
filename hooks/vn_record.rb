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
require $ione_conf['DataBase']['adapter']
$db = Sequel.connect({
        adapter: $ione_conf['DataBase']['adapter'].to_sym,
        user: $ione_conf['DataBase']['user'], password: $ione_conf['DataBase']['pass'],
        database: $ione_conf['DataBase']['database'], host: $ione_conf['DataBase']['host']  })

class AR < Sequel::Model(:ars); end

AR.create do | r |
    r.vnid  = ARGV.first
    r.arid  = ARGV.last == 'crt' ? 0 : -1
    r.time  = Time.now.to_i
    r.state = ARGV.last
end