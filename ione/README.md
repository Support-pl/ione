# Integrated OpenNebula Cloud Server API and toolkit documentation
[Homepage](https://ione-cloud.net)
[Docs](https://docs.ione-cloud.net)
[GitHub](https://github.com/ione-cloud)
[Creators](https://support.by)

## Feature List

**1. Automate processes inside your OpenNebula Cloud**

**2. Integrate OpenNebula Cloud to your infrastructure**

**3. Create your applications based on OpenNebula Cloud**

## Usage

### Configuring your IONe

IONe has the main config file, it's placed at the IONe root directory:

```sh
$ ls $IONEROOT | grep config
ione.conf
```

Main config file is consists of several main keys:

* OpenNebula

```yaml
OpenNebula:
  endpoint: 'http://localhost:2633/RPC2' # RPC endpoint for OpenNebula
  users-group: 1 # Main group for Basic Users
  users-default-lang: en_US # Default locale for new users
  users-vms-ssh-port: 22 # Default SSH-port at VMs instantiated from your templates
  base-vnc-port: 5900 # Base VNC-port number. VMs will get port for VNC by formula: {{ base-vnc-port }} + {{ vmid }}
```

* Server

```yaml
Server:
  # Port for IONe to listen
  listen-port: '8080'
```

* Include

```yaml
Include: # IONe libraries to include 
  - 'std++'
  - 'vmcontrol'
  - 'vminfo'
  - 'server'
  - 'data_import_handler'
  - 'useful_things'
  - 'creative_funcs'
```
Type names of directories, where your libraries are placed.
See more, about IONe libraries [here](#label-Managing+modules+and+libraries).

* Modules

```yaml
Modules: # IONe modules to connect
  - 'ansible'
  - 'stat'
```
Type names of directories, where your modules are placed.
See more, about IONe modules [here](#label-Managing+modules+and+libraries).

* Scripts

```yaml
Scripts: # Automation scripts to start
  - 'snap-controller'
```
Type names of directories, where your scripts are placed.
See more, about IONe automation scripts [here](#label-Creating+automation+scripts+for+IONe).

* vCenter

```yaml
vCenter:
  cpu-limits-koef: 1000 # By editing this key, you may configure the CPU units, which are used at vCenter VM limits configuration {VirtualMachine#getResourcesAllocationLimits methods}.
  drives-iops: # Type here default IOps value for each drive type
    HDD: 1000
    SSD: 5000
```

* SnapshotController

```yaml
SnapshotController:
  check-period: 3600 # Snapshots check period in seconds
```

### Using IONe as toolkit

IONe defines functions and methods for making your developing process for OpenNebula Cloud much easier and faster. Also, we provide some functions, which OpenNebula can't do, such as {VirtualMachine#setResourcesAllocationLimits vCenter vm allocation configuration}. This functions helped us to build stable and automated infrastructure, hope it will help you.
More info look at {ONeHelper} instance reference.

### Using CLI utility for IONe

After installing IONe, _ione_ cli utility will be installed automaticaly.

Let's check functionality.

#### Controling the IONe server

You can control you server:

```sh
$ ione server start   # Will start the IONe server using systemctl
$ ione server stop    # Will stop the IONe server using systemctl
$ ione server restart # Will restart the IONe server using systemctl
```
So, `ione server` call is the alias for `systemctl {command} ione`

#### Reading IONe logs

```sh
$ ione log      # Prints the main IONe log
       debug    # Prints IONe debug log, you may see all system messages here
       snapshot # Prints snapshot controller log
```

Now, you also may check the number of lines in log file:

```sh
$ ione log size
939
```
> Note: IONe wipes the log file at startup, if number of lines is more than 1000.

Also, you may check the path to log file:

```sh
$ ione log path
/var/log/ione/ione.log
```

It's may be usefull, for using _tail -f_.

After you have specified the log file you want to read, you may write the number of lines to print:

```sh
$ ione log 16   # Will print sixteen lines of main log file

       ################################################################
       ##                                                            ##
       ##    Integrated OpenNebula Cloud Server v0.8.8 - testing     ##
       ##                                                            ##
       ################################################################

[ Thu Mar 22 18:06:24 2018 ] Initializing JSON-RPC Server...
[ Thu Mar 22 18:06:24 2018 ] Server initialized

$
```

If you have typed number of lines to print, you may print it in _tail -f_ mode, use the follow key:

```sh
$ ione log 16 follow

       ################################################################
       ##                                                            ##
       ##    Integrated OpenNebula Cloud Server v0.8.8 - testing     ##
       ##                                                            ##
       ################################################################

[ Thu Mar 22 18:06:24 2018 ] Initializing JSON-RPC Server...
[ Thu Mar 22 18:06:24 2018 ] Server initialized
```

> Note: Refresh period is above 3-5 seconds!

#### Checking system information

* Server uptime:

```sh
$ ione uptime
0d:23h:19m:54s
```

* IONe current version:

```sh
$ ione version
0.8.8 - stable
```

## Developing

### Working with scopes

You should know about the scopes defined inside the IONe for creating modules, scripts and libraries.
So the basic scopes are: __main__ and __IONe__. You may see which classes and functions available from IONe class scope only.
> Note: Functions and classes from ONeHelper module are available from __main__(global) scope.

#### Main scope

Functions, classes and variables defined at __main__ scope available everywhere at the IONe system, you may use them directly at your scripts, modules and libraries.

* For example:

```rb
client = OpenNebula::Client.new('oneadmin:secret')
loop do # Rebooting VM #777 every hour if it's at the state RUNNING
  onblock(:vm, 777, client) do | vm |
    vm.info!
    vm.reboot if vm.lcm_state_str == 'RUNNING'
  end
  sleep(30)
end
```

#### IONe scope

Functions, which are available as JSON-RPC methods are defined as {IONe} class methods. Remember this, if you want your funcional to be available from network.

* For example:

```rb
# Calling Reboot method for VM #777 from network
require 'zmqjsonrpc'
ZmqJsonRpc::Client.new('tcp://your.domain:8008').Reboot(777)

# Doing the same stuff from the module
IONe.new($client).Reboot(777)
```


### Creating automation scripts for IONe

### Creating libraries with your functional

### Writing your own modules for IONe

IONe module is also the kind of Ruby Gem. The difference between libraries and modules is that modules are including later than libraries and modules, also, modules may have some background activities, libraries - not(it's can cause some exceptions and broke the whole systems, because libraries are the __'core'__ of the _IONe_ system).

* IONe module structure

Your module should starts from the _main.rb_ file inside your module directory.
If your module have some constants, you may put it to the _ione.conf_.

* For example

```yml
  ModuleName:
    some-variable: 'some-value'
    some-array:
      - 'array-member0'
      - 'array-member1'
```

So, you'll have this inside your programm:

```rb
  puts $ione_conf
  # => {
  #   * * *
  # 'ModuleName' => {
  #   'some-variable' => 'some-value',
  #   'some-array' => ['array-member0', 'array-member1']
  # }
  #   * * *
  # }
```

So, the basic structure should you have is:

```
modulename/:
|-- main.rb
|-- ione.conf
|-- 'any data you wish to store and use here'
```

Remember, that your module should can be activated by including it:

```rb
  require 'ione-telegram-bot/main.rb' # ~> Here the Telegram bot server starts 
```

Please, separate the _'passive'_ functional: _variables, functions, classes_, and the _'active'_ functional like servers, events handlers and etc.

You may use all available libraries and modules for your module, but remember about [basic scopes](#label-Working+with+scopes)

### IONe structure

IONe server structure is:

```sh
$IONEROOT/:
|-- ione.rb # IONe bootstrapper
|-- ione.conf # Basic IONe config
|-- daemon.rb # IONe daemon(kind of power key)
|-- Gemfile
|-- debug_lib.rb # IONe bootstrapper replication, you may use it for tests at irb
|-- .debug_conf.yml # Config for debug_lib.rb
|-- service
|   |-- on_helper.rb # ONeHelper ruby module
|   |-- log.rb # Log functions
|   |-- time.rb # Time functions
|
|-- lib
|   |-- %default and user libraries%
|
|-- modules
|   |-- %modules you have installed%
|
|-- scripts
|   |-- %your automation scripts%
|
|-- meta
|   |-- version.txt

$IONELOGROOT/:
|-- ione.log # Main IONe log
|-- snapshot.log # All logs, with SnapshotController method sended are here
|-- debug.log # Debug logs
|-- old.log # Old logs from ione.log
|-- errors.txt # Daemon errors stores here

/usr/bin/:
|-- ione # IONe CLI utility

/lib/systemd/system/:
|-- ione.service # IONe SystemD service
```

### Additional setup

  1. **Datastores**. 
    Every system datastore must have the next attributes:
    * DEPLOY - TRUE or FALSE, if set to false, this datastore will not be used for deployments
    * DRIVE_TYPE - SSD, HDD, NVMe, etc. Used for CreateVMwithSpecs and Reinstall when choosing DS for deployment
  2. **VM Templates**
    * PAAS_ACCESSIBLE

### Available modules

1. [Ansible](https://github.com/ione-cloud/ione-ansible)

2. [WHMCS API caller](https://github.com/ione-cloud/ione-whmcsapi)

### Available solutions based on IONe

1. {file:WHMCS.md WHMCS Automation Module (PaaS)}

## LICENSE