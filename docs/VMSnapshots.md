# IONe brings some features around VM Snapshots

## Snapshots restriction

`SNAPSHOTS_ALLOWED_DEFAULT` setting set to `FALSE`(defaults to `TRUE`) at IONe::Settings would disallow to create VM Snapshots without `SNAPSHOTS_ALLOWED` VM attribute set to `TRUE`.

## Snapshots quota

You can set quota for snapshots by setting `SNAPSHOTS_QUOTA` attribute to amount allowed.

## Billing

Setting `SNAPSHOT_COST` setting would make showback engine bill VMs per snapshot.

## Hint

To disallow user to change these attributes, you can set `VM_RESTRICTED_ATTR` to:

```shell
VM_RESTRICTED_ATTR = "USER_TEMPLATE/SNAPSHOTS_ALLOWED"
VM_RESTRICTED_ATTR = "USER_TEMPLATE/SNAPSHOTS_QUOTA"
```
