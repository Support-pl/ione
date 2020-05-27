# OpenNebula Sunstone with IONe integration

## Contacts
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
    <img src="https://img.shields.io/static/v1?label=version&message=v0.9.1&color=success&style=flat" alt="version"/>
</p>

Creators:
[Support.pl](https://support.pl)
[slnt_opp](http://slnt-opp.xyz)


## Main additional features
 * Transparent showback
 * Balance
 * Modified user interface for VDC

## System requirements
<table>
   <thead>
      <tr>
         <th align="left">Package/Service/App</th>
         <th align="center">Version</th>
         <th align="center">Optional?</th>
      </tr>
   </thead>
   <tbody>
      <tr>
         <td align="left">CentOS</td><td align="center">6/7</td><td align="center">Tested on this plaform only</td>
      </tr>
      <tr>
         <td align="left">OpenNebula</td><td align="center">5.8+</td><td align="center"></td>
      </tr>
      <tr>
         <td align="left">Sunstone</td><td align="center">^^^^</td><td align="center"></td>
      </tr>
      <tr>
         <td align="left">MySQL MariaDB Server</td><td align="center">~5.5</td><td align="center"></td>
      </tr>
      <tr>
         <td align="left">Ruby</td><td align="center">2.0.0</td><td align="center"></td>
      </tr>
      <tr>
         <td align="left">Ansible</td><td align="center">2.x.x</td><td align="center">yes</td>
      </tr>
      <tr>
         <td align="left">vCenter</td><td align="center">6.0/6.5/6.7</td><td align="center">yes</td>
      </tr>
      <tr>
         <td align="left">KVM-QEMU</td><td align="center">latest</td><td align="center">yes</td>
      </tr>
      <tr>
         <td align="left">Azure (ASM)</td><td align="center">—</td><td align="center">yes</td>
      </tr>
      <tr>
         <td align="left">Azure (ARM)</td><td align="center">—</td><td align="center">yes</td>
      </tr>
      <tr>
         <td align="left">Amazon EC2</td><td align="center">—</td><td align="center">yes</td>
      </tr>
   </tbody>
</table>


## Install

>If you are using a RedHat based distribution install redhat-lsb

1. Download this repo using:

   `git clone https://github.com/ione-cloud/***`

2. Enter directory:

    `cd ione-sunstone/`

3. Run install script as root:

    `rake install`
> Note:
> Works only with CentOS for now.

> Note:
> Additionaly installer isn't tested much times, so it's quite "buggy".

4. Wait for complection.

5. Fill `/etc/one/ione.conf` for proper work of IONe

6. Fill `/usr/lib/one/sunstone/ione/modules/ansible/config.yml` for proper work of Ansible module

    6.1. Add oneadmin ssh-key to Ansible authorized_hosts list

7. Fill all settings using UI. Panel "Cloud" at Settings tab._(Accessible only as oneadmin)_:

<table>
   <thead>
      <tr>
         <th align="left">Key</th>
         <th align="left">Subkey</th>
         <th align="right">Value</th>
      </tr>
   </thead>
   <tbody>
      <tr>
         <td align="left">__CAPACITY_COST__</td>
         <td align="left">CPU_COST</td>
         <td align="right"><code>CPU cost per hour</code></td>
      </tr>
      <tr>
         <td align="left"></td>
         <td align="left">MEMORY_COST</td>
         <td align="right"><code>RAM cost per hour</code></td>
      </tr>
      <tr>
         <td align="left">__DISK_COSTS__</td>
         <td align="left">DISKTYPE_0(e.g. SSD)</td>
         <td align="right"><code>cost per hour</code></td>
      </tr>
      <tr>
         <td align="left"></td>
         <td align="left">DISKTYPE_1(e.g. HDD)</td>
         <td align="right"><code>cost per hour</code></td>
      </tr>
      <tr>
         <td align="left">__DISK_TYPES__</td>
         <td align="left"></td>
         <td align="right"><code>comma separated list of types: SSD,HDD</code></td>
      </tr>
      <tr>
         <td align="left"><strong>PUBLIC_IP_COST</strong></td>
         <td align="left"></td>
         <td align="right"><code>cost per hour</code></td>
      </tr>
      <tr>
         <td align="left"><strong>IAAS_GROUP_ID</strong></td>
         <td align="left"></td>
         <td align="right"><code>ID of group for IaaS Users</code></td>
      </tr>
      <tr>
         <td align="left"><strong>PUBLIC_NETWORK_DEFAULTS</strong></td>
         <td align="left">NETWORK_ID</td>
         <td align="right"><code>Public IPs pool network ID</code></td>
      </tr>
      <tr>
         <td align="left"><strong>PRIVATE_NETWORK_DEFAULTS</strong></td>
         <td align="left">NETWORK_ID</td>
         <td align="right"><code>Private Networks pool network ID</code></td>
      </tr>
      <tr>
         <td align="left">__NODES_DEFAULT__</td>
         <td align="left">HYPERIVSOR_0(e.g. VCENTER)</td>
         <td align="right"><code>OpenNebula host id</code></td>
      </tr>
      <tr>
         <td align="left"></td>
         <td align="left">HYPERIVSOR_0(e.g. KVM)</td>
         <td align="right"><code>OpenNebula host id</code></td>
      </tr>
      <tr>
         <td align="left">__CURRENCY_MAIN__</td>
         <td align="left"></td>
         <td align="right"><code>$/€/etc... this will be shown to user</code></td>
      </tr>
   </tbody>
</table>
---------------------------------------------------------------------------------------------------------

Thanks for choosing us, contacts for support are in "Contacts" section at the start of this `README`
