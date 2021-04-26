# VLAN IDs Manager

## Synopsis

IONe brings VLAN IDs Manager sub-system.
By default, OpenNebula automatic VLAN lease system is just assigning new network ID as a VLAN_ID.
Sometimes(quite as often), actual VLAN IDs pool can begin from different ID(not 0, but e.g. 2000), have reserved VLANs etc.

IONe tries to solve this problem.

## Models

IONe brings two Models(and, respectively, classes).

### VLAN(:vlans)

Table of VLAN IDs ranges. Structure:

```markdown
+-------+--------------+------+------------------------------------------------------+
| Field | Type         | Null | Description                                          |
+-------+--------------+------+------------------------------------------------------+
| id    | int          | NO   | Key                                                  |
| start | int          | NO   | Start of range, e.g. 0                               |
| size  | int          | NO   | Amount of VLANs, e.g. 4096                           |
| type  | varchar(255) | NO   | vcenter, 802.1Q or other possible VN_MAD using VLANs |
+-------+--------------+------+------------------------------------------------------+
```

See {VLAN} class for available methods.

### VLANLease(:vlan_leases)

Table of VLAN IDs leases. All of the used VLAN IDs are supposed to be in this table.
Structure:

```markdown
+---------+------+------+---------------------------+
| Field   | Type | Null | Description               |
+---------+------+------+---------------------------+
| key     | int  | NO   | Key                       |
| vn      | int  | YES  | OpenNebula VirtualNetwork |
| id      | int  | NO   | VLAN ID                   |
| pool_id | int  | NO   | VLAN IDs Pool             |
+---------+------+------+---------------------------+
```

This table has validator: all three fields together gotta be unique.

## Configuration

> Note:
> You don't need to access DB directly. Only IONe Admin UI and Sunstone should be used.

### VN Templates

You would need the VN Template(s) to let {VLAN#lease} lease VLANs.

Example:

```bash
BRIDGE = "some_bridge"
PHYDEV = "br0"
VN_MAD = "802.1Q"
TYPE = "PRIVATE"
```

> Let's say we saved it, so we have VNTemplate with ID 10

### IONe Settings

You would need to fill only one {IONe::Settings} field - `VNETS_TEMPLATES`.

Example:

```json
{
  "802.1Q": 10
}
```

## How do you manage records {VLANLeases}

### {VLAN} class

Best approach is to use this class to manage VLANs. So if you create VNs and reserve VLANs with {VLAN#lease} and {VLAN#reserve} respectively, these methods will handle or recording operations.

### {VLANLease} class

Just delete lease record with {VLANLease#release} method.(It is basically just an alias)

