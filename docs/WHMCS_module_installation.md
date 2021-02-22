# Installation and configuration of Open Nebula Connect for WHMCS

## Installation and configuration of the module in WHMCS (Open Nebula Control)

1. Place the module in these directories on the server:

    ```shell
    /modules/servers/onconnector/
    /modules/addons/oncontrol/
    ```

2. At `Setup - Addon Modules` tab activate this module (Open Nebula Control)

3. You can add user immunity from blocking (if necessary).
    Go to `Setup - Custom client fields`, add a field with type `Drop down` with options (Not installed, Yes, No)
    > Note for WHMCS 8+:
    > wrench icon in the footer – System Setting – Custom Fields)

4. Add the server to `Setup - Products / services - Servers - Add a new server`, write down `Name` and `IP address`)

5. Open the module (`Addons - Open Nebula Control`) and fill in the data at tab `Configuration - Configure module`:

    * WHMCS admin username - administrator login, on behalf of which some functions of the module will work
    * IONe host address - url address of OpenNebula like <https://ione-api.example.com>
    * ON Login – administrator login for OpenNebula (for example oneadmin or CloudAdmin)
    * ON Password – administrator password for OpenNebula
    * Immunity - the name of the custom field for determining the immunity of the user

## Preconfiguration of WHMCS for the further IONE module integration

1. Add the list of IPs from which you can connect to the WHMCS API (address of server with IONe) at `Setup - General Settings - Security - API IP Access Restriction`

    > Note for WHMCS 8+: `wrench icon in the footer – System Setting – GeneralSettings – Security - API IP Access Restriction`

2. Add a product group, for example, VDS at `Setup - Products / Services - Create a new group` and add the product to this group.

    > Note for WHMCS 8+: `wrench icon in the footer – System Setting – Products/ Services - Create a new group`

3. Create a new product, e.g. VDS

    * Then, open the `Module Settings` tab
    * In the field `Module Name` choose `IONe` 
    * Next, you need to fill in the configuration fields of the virtual machine:

        * vCPU – quantity of cores (number)
        * RAM – amount of RAM (number)
        * DISK – disk type (datastore on which virtual machine will bedeployed - e.g. SSD, HDD, etc.)
        * DISK VALUE – amount of disk memory (GB)
        * NODE TYPE – node on which virtual machine will be deployed
        * SNAPSHOT – will snapshots be available on the machine

    * Next, select the option in which case the machine will be automatically installed.

4. Create an addon to the product:

    * `Setup - Products and services - Products Addons - Add new addon`
        > Note for WHMCS 8+: `wrench icon in the footer – System Setting – ProductsAddons - Add New Addon`
    * In order for the addon to be displayed when ordering, you must check the `Show on Order` checkbox.
    * Then, open the `Module Settings` tab, in the field `Module Name` choose `IONE`.
    * Next, you need to fill in the configuration fields of the virtual machine.
        > These settings are summed up with the settings from the product (previousitem), i.e. if the product had vCPU = 2, and in the addon that was added to the product vCPU = 1, then as a result the virtual machine will get vCPU = 3.

        * vCPU - the quantity of cores (number) that will be added to the parameters from the product (can be left blank)
        * RAM - the amount of RAM that will be added to the parameters from theproduct (you can leave it empty)
        * DISK - the type of disk from the add-on is not considered when creatingthe machine
            > i.e. if the product had DISK = SSD, DISK VALUE = 20, and in the add-on DISK = HDD, DISK VALUE = 30 - the virtual machine will get 50 GB of SSD disk.
        * DISK VALUE - The amount of disk space (GB) to be added to theparameters from the product.
        * NODE TYPE - the field from the add-on is not considered (i.e. when installing the machine, the parameter from the product will be used)
        * SNAPSHOT - whether snapshots will be available on the machine
            > if either in the product or in the add-on this option is enabled, the snapshots will be available on the machine
        * OS - is the add-on an operating system
            > necessary in order to configure operating system templates

    * After configuring all addons, you need to return to the `OpenNebula Control` module, to the `Configuration` tab - `Configure Templates` and add operating system templates
        > 1 addon corresponds to one template, the Template ID field is the template id in OpenNebula.



## Test Order

1. Add a new order.
2. Product/Service = VDS(if you named it VDS on previous step)
3. Addons to install a virtual machine, one add-on must be selected, configured as OS (previous section: configuration settings of operating systems).
    > If several add-ons of the operating network are selected, the first created one will be selected)
4. `Create order → Accept order.`
5. In case of an error, it can be debugged in the menu: `Utilities → Logs → Module Log`.
