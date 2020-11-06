## Synopsis
ISP Driver for OpenNebula Provides connection between OpenNebula and ISP BillManager.

## Installation
1. Clone [github repo](https://github.com/ione-cloud/isp_driver) or download and unpack it.
2. Put `vmm` to `~oneadmin/remmotes`
3. Put `im` to `~oneadmin/remmotes`
4. Paste code from `driver.conf` into `/etc/one/oned.conf`
5. Install `gem rest-client`

## Configuration
1. Create Host with IM and VM Mads `isp`
2. Add attribute `BASE_URL` with the value `https://your.isp.billmgr`
3. Add attribute `USERNAME` with your Billmgr account username
> Note: Admin account should not be used
4. Add attribute `PASSWORD` with the password for your account
5. Add attribute `DATACENTER` with the ISP datacenter ID
6. _optional_ Add attribute `HYPERVISOR` with the value `isp`

## Features
1. Creating VMs
2. Controlling VMs
3. Polling VMs
4. Import Helper

### Creating VMs
Define OpenNebula Template, here is an example:

```
HYPERVISOR = "ISP"
ISP_RAW_DATA = "JTdCJTIyU2V0...0EwJTdEJTdEJTdE" # Base64 encoded data from import helper
ISP_VARS = [
  ADDON_15 = "1024", # RAM in Mb
  ADDON_16 = "30", # to install ISP Panel or not
  ADDON_18 = "1", # CPU
  ADDON_20 = "10240", # Drive in Gb
  ADDON_22 = "1", # Billing period
  ADDON_23 = "1", 
  ADDON_24 = "0",
  AUTOPROLONG = "1",
  OSTEMPL = "ISPsystem__CentOS-7-amd64",
  PRICELIST = "13", # Tariff Plan
  RECIPE = "null" ] # Software to install
```

deploy driver will order VM using addons from template and update password using vmmgr

### Controlling VMs
Driver signs in BillManager and parses access data for VMManager, to control it.

### Polling VMs
Poll driver provides data about IP address(es) and VM state. elid from BillManager works as DeployID for OpenNebula

### Import Helper
Due to ISP Billmgr API imperfection, every single VM attribute, such as CPU, RAM or Software to install, is defined by random addon(smth like addon_1, addon_2, etc). Driver can't create VM without defining this addons in VM Template. Import Helper makes it a bit easier by listing every addon with description from UI.