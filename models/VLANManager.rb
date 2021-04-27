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

begin
  $db.create_table :vlans do
    primary_key :id
    Integer     :start, null: false # Start of range, e.g. 0
    Integer     :size,  null: false # Amount of VLANs, e.g. 4096
    String      :type,  null: false # vcenter, 802.1Q or other possible VN_MAD using VLANs
  end
rescue
  puts "Table :vlans already exists, skipping"
end

begin
  $db.create_table :vlan_leases do
    primary_key :key
    # Network Instantiated with this VLAN ID
    # Note: In order to delete lease record just delete VNet
    foreign_key :vn, :network_pool, null: true, on_delete: :cascade
    Integer     :id, null: false               # VLAN ID
    foreign_key :pool_id, :vlans, null: false  # VLAN Pool ID
    unique      [:vn, :id, :pool_id]
  end
rescue
  puts "Table :vlan_leases already exists, skipping"
end

# Table of VLAN IDs leases Model Class
class VLANLease < Sequel::Model(:vlan_leases)
  many_to_one :vlan_key

  alias :release :delete

  # Needed for serialization
  def to_json *args
    @values.without(:key).to_json(*args)
  end

  def self.all_with_meta id = nil
    (id ? VLANLease.where(pool_id: id) : VLANLease).all.map do | vl |
      vl.hash_with_meta
    end
  end

  def hash_with_meta
    to_hash.without(:key).merge(vn_name: $db[:network_pool].where(oid: vn).select(:name).first[:name])
  end
end

# Table of VLAN IDs ranges Model Class
class VLAN < Sequel::Model(:vlans)
  # Returns first VLANs pool with available VLAN or raises VLAN::NoAvailavleVLANsPoolsLeftException
  # @return [ VLAN ]
  def self.available_pool
    VLAN.all.each do | vlan |
      return vlan if vlan.check_free_vlans
    rescue VLAN::NoFreeVLANsLeftException
      next
    end
    raise VLAN::NoAvailavleVLANsPoolsLeftException.new
  end

  def self.all_with_meta
    VLAN.all.map do | v |
      v.hash_with_meta
    end
  end

  def hash_with_meta
    to_hash.merge(leased: VLANLease.where(pool_id: id).count)
  end

  def hash_with_meta_and_leases
    hash_with_meta.merge(leases: VLANLease.where(pool_id: id).all)
  end

  # Returns all existing lease records
  # @return [Array<VLANLease>]
  def leases
    VLANLease.where(pool_id: id).all
  end

  # Returns VLAN ID would be assigned with next lease
  # Also saves it to local variable to reduce transactions
  # @return [Integer | NilClass] - either ID or nil if no free VLANs left
  def next_id
    @next_id = ((start...(start + size)).to_a - leases.map { |l| l.id }).first
  end

  # Checking if any free VLANs left in Pool
  # Will raise StandardError if no left
  # @return [ TrueClass ]
  def check_free_vlans
    raise VLAN::NoFreeVLANsLeftException.new(id) if next_id.nil?

    true
  end

  # Create new VNet and lease record with VLAN ID from this Pool
  # @param [String] name - New VNet Name
  # @param [Integer] owner - OpenNebula::User ID. New VNet would be bind to that user
  # @param [Integer] group - OpenNebula::Group ID. New VNet would be bind to that group
  # @return [Integer] - New OpenNebula::VirtualNetwork ID
  def lease name, owner = 0, group = 0
    template = IONe::Settings['VNETS_TEMPLATES'][type]
    if template.nil? then
      raise StandardError.new("No Template for VN_MAD #{type} configured")
    else
      template = OpenNebula::VNTemplate.new_with_id(template.to_i, $client)
    end

    rc = template.info!
    if OpenNebula.is_error? rc then
      raise rc
    end

    check_free_vlans

    rc = template.instantiate(name, "VLAN_ID=#{@next_id}")
    if OpenNebula.is_error? rc then
      raise rc
    end

    VLANLease.insert(vn: rc, id: @next_id, pool_id: id)

    vnet = OpenNebula::VirtualNetwork.new_with_id(rc, $client)
    vnet.chown(owner, group)
    vnet.id
  end

  # Reserve VLAN ID(so it won't be used for new VNets)
  # @param [Integer] vlan_id - VLAN ID to reserve
  # @param [Integer] vn - Made for manual record creation, vn to lease to
  # @return [TrueClass] - returns true if it worked out, or raises Exception if not
  def reserve vlan_id, vn = nil
    unless (start...(start + size)).include? vlan_id then
      raise StandardError.new("Requested VLAN ID isn't a part of this Pool(#{id})")
    end

    lease =
      if vn.nil? then
        VLANLease.where(id: vlan_id, pool_id: id).first
      else
        VLANLease.where(vn: vn, id: vlan_id, pool_id: id).first
      end

    unless lease.nil? then
      raise StandardError.new("Requested VLAN ID is already leased")
    end

    unless vn.nil? then
      VLANLease.insert(vn: vn, id: vlan_id, pool_id: id)
    else
      VLANLease.insert(id: vlan_id, pool_id: id)
    end
    true
  end

  # No Free VLANs Left Exception
  class NoFreeVLANsLeftException < StandardError
    def initialize id
      super("No free VLANs left at VLANs Pool(#{id})")
    end
  end

  # No VLANs Pools with free VLANs Left Exception
  class NoAvailavleVLANsPoolsLeftException < StandardError
    def initialize
      super("No Availavle VLANs Pools Left")
    end
  end

  # Needed for serialization
  def to_json *args
    @values.without(:key).to_json(*args)
  end
end

get '/vlan' do
  begin
    raise StandardError.new("NoAccess") unless @one_user.admin?

    json response: VLAN.all_with_meta
  rescue => e
    json error: e.message
  end
end

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

get '/vlan/:id' do | vlan_id |
  begin
    raise StandardError.new("NoAccess") unless @one_user.admin?

    json response: VLAN.where(id: vlan_id).first.hash_with_meta_and_leases
  rescue => e
    json error: e.message
  end
end

delete '/vlan/:id/delete' do | vlan_id |
  begin
    raise StandardError.new("NoAccess") unless @one_user.admin?

    VLAN.where(id: vlan_id).delete
    json response: true
  rescue => e
    json error: e.message
  end
end

post '/vlan/:id/lease' do | vlan_id |
  begin
    raise StandardError.new("NoAccess") unless @one_user.admin?

    data = JSON.parse(@request_body)
    json response: VLAN.where(id: vlan_id).first.lease(*data['params'])
  rescue => e
    json error: e.message
  end
end
