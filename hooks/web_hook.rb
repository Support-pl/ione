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

require 'net/http'
require 'json'

ALPINE = ENV["ALPINE"] == "true"

hook, *args = ARGV
hook = hook.split('/').last

api = URI("http://ione:8009/")
unless ALPINE then
  api = URI("http://localhost:8009/")
end
req = Net::HTTP::Post.new(api + '/hooks/' + hook)
if ALPINE then
  # Reading credentials from ENV and using as #basic_auth(uname, passwd)
  req.basic_auth(*ENV['IONE_AUTH'].split(':'))
else
  req.basic_auth(Client.new.one_auth)
end
req.body = JSON.generate params: args

r = Net::HTTP.start(api.hostname, api.port) do | http |
  http.request(req)
end
res = JSON.parse r.body

case r.code.to_i
when 400
  STDERR.puts res['error']
  exit 1
when 403
  STDERR.puts "Forbidden"
  exit 1
else
  STDOUT.puts res['stdout']
  STDERR.puts res['stderr']
  exit res['status']
end
