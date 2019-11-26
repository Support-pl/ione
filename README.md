# OpenNebula Sunstone with IONe integration

### Contacts
<p align="left">
    <a href="https://ione-cloud.net" title="Project Homepage" rel="nofollow">
        <img src="https://img.shields.io/static/v1?label=Project&message=HomePage&color=blue&style=flat" alt="Project Homepage"/>
    </a>
    <a href="https://docs.ione-cloud.net" title="IONe Docs Page" rel="nofollow">
        <img src="https://img.shields.io/static/v1?label=IONe&message=Docs&color=informational&style=flat" alt="IONe Docs Page"/>
    </a>
    <a href="https://github.com/ione-cloud" title="github" rel="nofollow">
        <img src="https://img.shields.io/static/v1?label=github&message=repo&color=green&style=flat" alt="github"/>
    </a>
    <img src="https://img.shields.io/static/v1?label=version&message=v0.9.0&color=success&style=flat" alt="version"/>
</p>

Creators:
[Support.pl](https://support.pl)
[slnt_opp](http://slnt-opp.xyz)


## Main additional features
 * Transparent showback
 * Balance
 * Modified user interface for VDC

## System requirements
|   Package/Service/App     |   Version         |   Optional?   |
|:--------------------------|:-----------------:|:-------------:|
|   CentOS	                |   6/7             |               |
|   OpenNebula	            |   5.4+            |               |
|   Sunstone	            |   ^^^^            |               |
|   MySQL MariaDB Server	|   ~5.5            |               |
|   Ruby	                |   2.0.0           |               |
|   Ansible             	|   2.x.x           |   yes         |
|   vCenter             	|   6.0/6.5/6.7     |   yes         |
|   KVM-QEMU            	|   latest          |   yes         |
|   Azure (ASM)             |	—               |   yes         |
|   Azure (ARM)             |	—               |   yes         |
|   Amazon EC2              |	—               |   yes         |


## Install

1. Download this repo using:

   `git clone https://github.com/ione-cloud/***`

2. Enter directory:

    `cd ione-sunstone/`

3. Run install script as root:

    `sudo ruby install.rb`
> Note:
> Works only with CentOS for now.

4. Wait for complection.

5. Fill `/etc/one/ione.conf` for proper work of IONe

6. Fill `/usr/lib/one/sunstone/ione/modules/ansible/config.yml` for proper work of Ansible module

    6.1. Add oneadmin ssh-key to Ansible authorized_hosts list

7. Fill all settings using UI. Panel "Cloud" at Settings tab._(Accessible only as oneadmin)_:

| Key                           | Subkey                    | Value                                     |
|:------------------------------|:--------------------------|------------------------------------------:|
| __CAPACITY_COST__             | CPU_COST                  | `CPU cost per hour`                       |
|                               | MEMORY_COST               | `RAM cost per hour`                       |
| __DISK_COSTS__                | DISKTYPE_0(e.g. SSD)      | `cost per hour`                           |
|                               | DISKTYPE_1(e.g. HDD)      | `cost per hour`                           |
| __DISK_TYPES__                |                           | `comma separated list of types: SSD,HDD`  |
| __PUBLIC_IP_COST__            |                           | `cost per hour`                           |
| __IAAS_GROUP_ID__             |                           | `ID of group for IaaS Users`              |
| __PUBLIC_NETWORK_DEFAULTS__   | NETWORK_ID                | `Public IPs pool network ID`              |
| __PRIVATE_NETWORK_DEFAULTS__  | NETWORK_ID                | `Private Networks pool network ID`        |
| __NODES_DEFAULT__             | HYPERIVSOR_0(e.g. VCENTER)| `OpenNebula host id`                      |
|                               | HYPERIVSOR_0(e.g. KVM)    | `OpenNebula host id`                      |
| __CURRENCY_MAIN__             |                           | `$/€/etc... this will be shown to user`   |
---------------------------------------------------------------------------------------------------------

Thanks for choosing us, contacts for support are in "Contacts" section at the start of this `README`
