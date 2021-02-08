# IONe

## Contacts

<p align="left">
    <a href="https://ione-cloud.net" title="Project Homepage" rel="nofollow">
        <img src="https://img.shields.io/static/v1?label=Project&message=HomePage&color=blue&style=flat" alt="Project Homepage"/>
    </a>
    <a href="https://docs.ione-cloud.net" title="IONe Docs Page" rel="nofollow">
        <img src="https://img.shields.io/static/v1?label=IONe&message=Docs&color=informational&style=flat" alt="IONe Docs Page"/>
    </a>
    <a href="https://github.com/ione" title="github" rel="nofollow">
        <img src="https://img.shields.io/static/v1?label=github&message=repo&color=green&style=flat" alt="github"/>
    </a>
    <img src="https://img.shields.io/static/v1?label=version&message=v1.0.1&color=success&style=flat" alt="version"/>
    <img src="https://github.com/ione-cloud/ione-sunstone/workflows/Generate%20and%20Deploy%20Docs/badge.svg" alt="Generate and Deploy Docs"/>
</p>

Creators:
[Support.pl](https://support.pl)
[slnt_opp](https://slnt-opp.xyz)

## Main additional features

- Transparent showback
- Balance
- Modified user interface for VDC

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
         <td align="left">CentOS</td><td align="center">8</td><td align="center">Tested on this plaform only</td>
      </tr>
      <tr>
         <td align="left">OpenNebula</td><td align="center">5.10(see <a href="https://github.com/ione-cloud/ione/releases">Releases</a> for <br/>older ONe versions)</td><td align="center"></td>
      </tr>
      <tr>
         <td align="left">MySQL MariaDB Server</td><td align="center">~8.0</td><td align="center"></td>
      </tr>
      <tr>
         <td align="left">Ruby</td><td align="center">2.5.5</td><td align="center"></td>
      </tr>
      <tr>
         <td align="left">Node</td><td align="center">12+</td><td align="center"></td>
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

> If you are using a RedHat based distribution install redhat-lsb

1. Download this repo using:
   `git clone https://github.com/ione-cloud/ione`

2. Enter directory:
   `cd ione`

3. Run install script as root:
   `rake install`

> Note:
> Works only with CentOS for now.

4. Wait for complection.

5. Fill `/etc/one/ione.conf` for proper work of IONe

6. Fill `/usr/lib/one/ione/modules/ansible/config.yml` for proper work of Ansible module

   6.1. Add oneadmin ssh-key to Ansible authorized_hosts list

7. Fill all settings using IONe UI at ione-admin.your.domain._(Accessible only as oneadmin)_:

8. Start the IONe up via `systemctl start ione`

> Note:
> If you're using RVM or other solution to control Ruby versions, you may need to update `ExecStart` section in `/usr/lib/systemd/system/ione.service` with relevant ruby executable and set `GEM_HOME` and `GEM_PATH` environment variables explicitly, example below:

```ini
ExecStart=/usr/local/rvm/rubies/ruby-2.5.8/bin/ruby /usr/lib/one/ione/ione_server.rb
Environment=GEM_HOME=/usr/local/rvm/gems/ruby-2.5.8
Environment=GEM_PATH=/usr/local/rvm/gems/ruby-2.5.8:/usr/local/rvm/gems/ruby-2.5.8@global
```

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
         <td align="left"><strong>CAPACITY_COST</strong></td>
         <td align="left">CPU_COST</td>
         <td align="right"><code>CPU cost per hour</code></td>
      </tr>
      <tr>
         <td align="left"></td>
         <td align="left">MEMORY_COST</td>
         <td align="right"><code>RAM cost per hour</code></td>
      </tr>
      <tr>
         <td align="left"><strong>DISK_COSTS</strong></td>
         <td align="left">DISKTYPE_0(e.g. SSD)</td>
         <td align="right"><code>cost per hour</code></td>
      </tr>
      <tr>
         <td align="left"></td>
         <td align="left">DISKTYPE_1(e.g. HDD)</td>
         <td align="right"><code>cost per hour</code></td>
      </tr>
      <tr>
         <td align="left"><strong>DISK_TYPES</strong></td>
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
         <td align="left"><strong>NODES_DEFAULT</strong></td>
         <td align="left">HYPERIVSOR_0(e.g. VCENTER)</td>
         <td align="right"><code>OpenNebula host id</code></td>
      </tr>
      <tr>
         <td align="left"></td>
         <td align="left">HYPERIVSOR_0(e.g. KVM)</td>
         <td align="right"><code>OpenNebula host id</code></td>
      </tr>
      <tr>
         <td align="left"><strong>CURRENCY_MAIN</strong></td>
         <td align="left"></td>
         <td align="right"><code>$/€/etc... this will be shown to user</code></td>
      </tr>
   </tbody>
</table>
---------------------------------------------------------------------------------------------------------

Thanks for choosing us, contacts for support are in "Contacts" section at the beginning of this `README`

## Important Notes

### CentOS, gem mysql2 and MariaDB

Most probably `gem install mysql2` will fail on building native extentions. The most common solutions here are:

1. Check if ruby-devel is installed correctly(`yum install ruby-devel` or `rvm install 2.5-devel`)
2. Check if package MariaDB-shared is installed(`yum install MariaDB-shared`, it's case-sensistive)
