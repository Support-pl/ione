# IONe brings some features around VM Snapshots

## Snapshots restriction

You can set `SNAPSHOTS_ALLOWED` VM attribute to `TRUE` or `FALSE` to allow or disallow user to create snapshots.

## Snapshots quota

You can set quota for snapshots by setting `SNAPSHOTS_QUOTA` attribute to amount allowed.

## Hint

To disallow user to change these attributes, you can set `VM_RESTRICTED_ATTR` to:

```shell
VM_RESTRICTED_ATTR = "USER_TEMPLATE/SNAPSHOTS_ALLOWED"
VM_RESTRICTED_ATTR = "USER_TEMPLATE/SNAPSHOTS_QUOTA"
```
