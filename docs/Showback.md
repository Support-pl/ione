# Notes about configuring VM Showback

## BILLING_PERIOD

Each and every VM should have BILLING_PERIOD defined in template.
Possible values are:
 - PAYG - VM will be billed per second
 - PRE_<% n_days %> - Pre-Paid per N days, e.g. `PRE_30`, then full Capacity and Disk cost will be charged on deploy, and then every 30 days.

## Traffic

Starting from Version 1.0.1 IONe is able to give showback for Traffic basing on RX, TX data from monitoring.

In order to enable it, you should do following steps:

1. Asure that your hypervisor does return and OpenNebula does collect traffic monitoring data as NETRX,NETTX values.
2. Set non-zero TRAFFIC_COST in IONe Admin Panel
3. Enable `traffic-recorder` script in `/etc/one/ione.conf`
4. Reload ione with `systemctl restart ione`

After doing this, you should begin getting traffic showback.
Traffic is being biller in 24h periods. Which means that you won't get bill immediately unless every step except step 2 has been already completed.

## Costs units

|  Field   |      Units      |
|----------|-----------------|
|   CPU    |   Core / sec    |
|   RAM    |    GB / sec     |
|  DRIVE   |    GB / sec     |
|    IP    |    Addr / month |
| Traffic  |     GB / sec    |
| Snapshot |    Snap / sec   |

