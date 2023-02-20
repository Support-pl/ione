# IONe modules for WHMCS

## Synopsis

If you wish to automate you hosting buisness cloud, including billing, you may use WHMCS with OpenNebula through IONe and our WHMCS modules.

## PaaS Provisioning

Check our [Cloud Automation Module for OpenNebula](https://marketplace.whmcs.com/product/4675) out, if you want to:

* Automate VDSs creation - module will create vms and users in OpenNebula automatically, as soon as product has status paid
* Suspend and Resume users and their VMs - module hooks will automatically suspend and unsuspend vms
* Terminate VDS, if user Account profile in WHMCS is terminated
* Automate software-installation with our Ansible inegration
* Create your own hooks and addons with OpenNebula Control SDK

## IaaS & VDC Provisioning

Our brand new module for billing and provisioning VDC users in OpenNebula, which allows you to create users in certain groups with VDC privileges, collect usage data and bill users based on it.
Two billing types are now supported: pay-as-you-go and reservation for x-days(debiting once in x days).
For more information check our [Virtual Datacenter Module for OpenNebula](https://my.support.pl/cart.php?gid=1) out.

## Installation

Installation guide [here](https://support-pl.github.io/ione/file.WHMCS_module_installation.html).
