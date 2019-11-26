# Installation and configuration of Open Nebula Connect for WHMCS

## Installation and configuration of the module in WHMCS (Open Nebula Control)

1. Place the module in these directories on the server:

```
/modules/servers/onconnector/
/modules/addons/oncontrol/
```

2. At `Setup - Addon Modules` tab activate this module (Open Nebula Control)

3. You can add user immunity from blocking (if necessary). 
Go to `Setup - Custom client fields`, add a field with type `Drop down` with options (Not installed, Yes, No)

4. Add the server to `Setup - Products / services - Servers - Add a new server`, write down `Name` and `IP address`)

5. Open the module (`Addons - Open Nebula Control`) and fill in the data:
 * WHMCS admin username - administrator login, on behalf of which some functions of the module will work
 * IONe host address - url address of OpenNebula like https://example.com
 * IP - ip address of Open Nebula
 * Port - port of Open Nebula
 * Immunity - the name of the custom field for determining the immunity of the user (the field created in paragraph 4).

6. Also in this interface (module settings) click `Configuration - Configure Templates` and add a template (template id from Open Nebula)

## Preconfiguration of WHMCS for the further IONE module integration

1. Add the list of IPs from which you can connect to the WHMCS API (address of server with ON) at `Setup - General Settings - Security - API IP Access Restriction`

2. Add a product group, for example, VDS at `Setup - Products / Services - Create a new group` and add the product to this group.

3. Create a new product - name VDS M
The most important field is the `product description`:

```json
{
    "properties": [
        {
            "GROUP": "cpu_core",
            "VALUE": "1",
            "TITLE": "1"
        },
        {
            "GROUP": "ram",
            "VALUE": "2 GB",
            "TITLE": "2 Gb"
        },
        {
            "GROUP": "hdd",
            "VALUE": "50 GB",
            "TITLE": "50 Gb",
            "IOPS": "250"
        },
        {
            "GROUP": "traffic",
            "VALUE": "100 GB",
            "TITLE": "100 Gb"
        }
    ]
}
```

Then, open the `Module Settings` tab, select the “IONe” module, enter the user group id from ON in the Group ID field

Create an addon to the product: 
```
Setup - Products and services - Products Addons - Add new Addon
```

The most important field is “description”, it should be similar to:

```json
{
    "GROUP": "os",
    "TITLE": "CentOS x64",
    "VALUE": "1"
}
```

Also there must be a tick “Show on Order”.

These settings of product and addons will be enough for VDS auto-installation, However, you can edit other parameters as you want (Price, Disk / RAM, Operating system name).

## Test Order

1. Add a new order.
2. Product/Service = VDS M
3. Addons = checkmark on OS-Linux CentOS x64
4. `Create order → Accept order.`
5. In case of an error, it can be debugged in the menu: `Utilities → Logs → Module Log`.
