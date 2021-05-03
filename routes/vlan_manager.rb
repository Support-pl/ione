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

# Endpoint returns all VLAN pools
# @see VLAN#all_with_meta
get '/vlan' do
  begin
    raise StandardError.new("NoAccess") unless @one_user.admin?

    json response: VLAN.all_with_meta
  rescue => e
    json error: e.message
  end
end

# Endpoint for VLAN pool creation
#   Required body with following scheme:
#   {
#     "start": Integer
#     "size" : Integer
#     "type" : String
#   }
post '/vlan' do
  begin
    raise StandardError.new("NoAccess") unless @one_user.admin?

    data = JSON.parse(@request_body)
    id = VLAN.insert(**data.to_sym!)
    json response: id
  rescue => e
    json error: e.message
  end
end

# Get particular VLAN pool object
# @see VLAN#hash_with_meta_and_leases
get '/vlan/:id' do | pool_id |
  begin
    raise StandardError.new("NoAccess") unless @one_user.admin?

    json response: VLAN.where(id: pool_id).first.hash_with_meta_and_leases
  rescue => e
    json error: e.message
  end
end

# Deletes VLAN pool
# @note All Leases gotta be deleted
delete '/vlan/:id/delete' do | pool_id |
  begin
    raise StandardError.new("NoAccess") unless @one_user.admin?

    VLAN.where(id: pool_id).delete
    json response: true
  rescue => e
    json error: e.message
  end
end

# Create Lease and VNet with VLAN ID from given VLAN pool
# @see VLAN#lease
post '/vlan/:id/lease' do | pool_id |
  begin
    raise StandardError.new("NoAccess") unless @one_user.admin?

    data = JSON.parse(@request_body)
    json response: VLAN.where(id: pool_id).first.lease(*data['params'])
  rescue => e
    json error: e.message
  end
end

# Create Lease without VNet or bind to existing VNet
# @see VLAN@reserve
post '/vlan/:id/reserve' do | pool_id |
  begin
    raise StandardError.new("NoAccess") unless @one_user.admin?

    data = JSON.parse(@request_body)
    json response: VLAN.where(id: pool_id).first.reserve(*data['params'])
  rescue => e
    json error: e.message
  end
end

# Delete VLANLease
# @see VLANLease#release
delete '/vlan/:id/lease/:lid' do | id, vlan_id |
  begin
    raise StandardError.new("NoAccess") unless @one_user.admin?

    json response: VLANLease.where(pool_id: id, id: vlan_id).release
  rescue => e
    json error: e.message
  end
end
