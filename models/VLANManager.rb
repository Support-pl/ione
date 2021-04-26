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
    foreign_key :vn, :network_pool, null: true, on_delete: :cascade # Network Instantiated with this VLAN ID
    Integer     :id, null: false               # VLAN ID
    foreign_key :pool_id, :vlans, null: false  # VLAN Pool ID
    unique      [:vn, :id]
  end
rescue
  puts "Table :vlan_leases already exists, skipping"
end

class VLANLease < Sequel::Model(:vlan_leases)
  many_to_one :vlan_key
end

class VLAN < Sequel::Model(:vlans)
  def leases
    VLANLease.where(pool_id: id).all
  end

end

