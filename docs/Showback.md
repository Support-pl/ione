# Notes about VM Showback

## BILLING_PERIOD

Each and every VM should have BILLING_PERIOD defined in template.
Possible values are:

- PAYG - VM will be billed per second
- PRE_<% n_days %> - Pre-Paid per N days, e.g. `PRE_30`, then full Capacity and Disk cost will be charged on deploy, and then every 30 days.

## Traffic

Starting from Version 1.0.1 IONe is able to give showback for Traffic basing on RX, TX data from monitoring.

In order to enable it, you should do following steps:

1. Asure that your hypervisor does return and OpenNebula does collect traffic monitoring data as `NETRX,NETTX` values.
2. Set non-zero `TRAFFIC_COST` in IONe Admin Panel
3. Enable `traffic-recorder` script in `/etc/one/ione.conf`
4. Reload ione with `systemctl restart ione`

After doing this, you should begin getting traffic showback.
Traffic is being biller in 24h periods. Which means that you won't get bill immediately unless every step except step 2 has been already completed.

## Costs units

<table>
  <thead>
    <tr>
      <th>Field</th>
      <th>Units</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>CPU</td>
      <td>Core / sec</td>
    </tr>
    <tr>
      <td>RAM</td>
      <td>GB / sec</td>
    </tr>
    <tr>
      <td>DRIVE</td>
      <td>GB / sec</td>
    </tr>
    <tr>
      <td>IP</td>
      <td>Addr / month</td>
    </tr>
    <tr>
      <td>Traffic</td>
      <td>GB / sec</td>
    </tr>
    <tr>
      <td>Snapshot</td>
      <td>Snap / sec</td>
    </tr>
  </tbody>
</table>

## How does this work? (PAYG)

### Capacity (CPU & RAM)

IONe brings multiple VM state hooks and `:records` DB table in order to build complete timeline.

`service/records/records.rb` creates `:records` table as:

<table>
  <thead>
    <tr>
      <th>Field</th>
      <th>Type</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>:id</code></td>
      <td>Integer</td>
      <td>VM ID</td>
    </tr>
    <tr>
      <td><code>:time</code></td>
      <td>Integer</td>
      <td>Timestamp</td>
    </tr>
    <tr>
      <td><code>:state</code></td>
      <td>String</td>
      <td>VM State, either <code>on</code>, <code>off</code> or <code>pnd</code></td>
    </tr>
  </tbody>
</table>

For example, as VM `#100`:

1. created(enters state `PENDING`) on `1 Jan. 1970 at 01:00:00`
2. starts (enters state `ACTIVE, RUNNING`) minute after
3. and stops(enters state `POWEROFF`) another minute after

then `active-running` hook would be invoked, which is executing script from `hooks/record.rb` with arguments `pnd`, `on`, `off` accordingly, so following records will be created:

```ruby
{ id: 100, time: 0, state: 'pnd' }
{ id: 100, time: 60, state: 'on' }
{ id: 100, time: 120, state: 'off' }
```

> Let's say CPU + RAM cost $1 per minute(60sec) in total

So if you request showback from `0` to `180`, IONe will compile Timeline:

```ruby
60sec => pnd
60sec => on
60sec => off
```

Which capacity biller understanding as

- $0 for pnd state
- $1 for on state
- $0 for off state

Total: $1

### Disk Biller

### Snapshots Biller

### Traffic Biller

## How does this work? (Pre-Paid)
