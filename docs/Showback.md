# Notes about configuring VM Showback

## BILLING_PERIOD

Each and every VM should have BILLING_PERIOD defined in template.
Possible values are:
 - PAYG - VM will be billed per second
 - PRE_<% n_days %> - Pre-Paid per N days, e.g. `PRE_30`, then full Capacity and Disk cost will be charged on deploy, and then every 30 days.