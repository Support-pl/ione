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
    <img src="https://img.shields.io/static/v1?label=version&message=v1.0.3&color=success&style=flat" alt="version"/>
    <img src="https://github.com/ione-cloud/ione-sunstone/workflows/Generate%20and%20Deploy%20Docs/badge.svg" alt="Generate and Deploy Docs"/>
</p>

Creators:
[IONe Cloud](https://ione-cloud.net)
[Support.pl](https://support.pl)
[slnt_opp](https://slnt-opp.xyz)

## Table of Contents

- [System requirements](#system-requirements)
- [Installation classic](#install)
- [Running in Docker](#running-in-docker)
- [Notes](#important-notes)

## Main features

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
         <td align="left">OpenNebula</td><td align="center">5.10+(see <a href="https://github.com/ione-cloud/ione/releases">Releases</a> for <br/>older ONe versions)</td><td align="center"></td>
      </tr>
      <tr>
         <td align="left">DataBase</td><td align="center"></td><td align="center"></td>
      </tr>
      <tr>
         <td align="right">MySQL MariaDB Server</td><td align="center">~8.0</td><td></td>
      </tr>
      <tr>
         <td align="right">PostgreSQL</td><td align="center">^13.3</td><td></td>
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
> If you're using RVM or other solution to control Ruby versions(as an example if you're using CentOS 7), you may need to update `ExecStart` section in `/usr/lib/systemd/system/ione.service` with relevant ruby executable and set `GEM_HOME` and `GEM_PATH` environment variables explicitly, example below:

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
         <td align="left">PAAS</td>
         <td align="right"><code>Public IPs pool network ID for PaaS</code></td>
      </tr>
      <tr>
         <td align="left"><strong></strong></td>
         <td align="left">IAAS</td>
         <td align="right"><code>Public IPs pool network ID for IaaS</code></td>
      </tr>
      <tr>
         <td align="left"><strong>VNETS_TEMPLATES</strong></td>
         <td align="left">VN_MAD(e.g. 802.1Q)</td>
         <td align="right"><code>VNs Types to VNs Templates mapping(types must be upper case)</code></td>
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

## Running in Docker

1. Download needed files using:

   ```shell
   mkdir ione && cd ione && \
   wget https://raw.githubusercontent.com/Support-pl/ione/master/sys/ione.conf && \
   wget https://raw.githubusercontent.com/Support-pl/ione/master/docker-compose.yml
   ```

2. Pre-configure IONe in `ione.conf` if needed
3. Configure credentials and endpoints in `docker-compose.yml` ([reference below](#docker-environment-variables-reference))

   3.1 You may need to change tags to anything else from `latest` sometimes. Check [Github packages](https://github.com/orgs/Support-pl/packages?repo_name=ione) to see latest published versions

4. Start IONe using `docker-compose up -d`

### Docker environment variables reference

```shell
ALPINE=true # just required to make IONe reading data from env instead of default ONe files
IONE_LOCATION=/ione # IONe root dir in container
ONE_LOCATION=/ione/sys # IONe configs dir path
LOG_LOCATION=/log # Path to dir to write IONe logs in
ONE_CREDENTIALS="oneadmin:passwd" # oneadmin or other ONe admin(!) user credentials
ONE_ENDPOINT="http://localhost:2633/RPC2" # ONe XML-RPC API endpoint

# Database connection(must be same DB with ONe and have at least READ access to ONe tables)
DB_BACKEND=mysql
DB_HOST=10.6.6.6
DB_USER=oneadmin
DB_PASSWORD:passwd
DB_DATABASE=opennebula
```

Thanks for choosing us, contacts for support are in "Contacts" section at the beginning of this `README`

## Important Notes

### CentOS, gem mysql2 and MariaDB

Most probably `gem install mysql2` will fail on building native extentions. The most common solutions here are:

1. Check if ruby-devel is installed correctly(`yum install ruby-devel` or `rvm install 2.5-devel`)
2. Check if package MariaDB-shared is installed(`yum install MariaDB-shared`, it's case-sensistive)

## Useful Doc-Pages

- [WHMCS Module Overview and Installation guides](/file.WHMCS.html)
- [Showback Configuration Reference](/file.Showback.html)
- [Snapshots management features and billing reference](/file.VMSnapshots.html)
- [VLAN Manager reference](/file.VLANManager.html)
