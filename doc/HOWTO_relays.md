# Relays

## Overview
A relay is a wifi-enabled outlet.  Facilities often use these to control the power for a monitor or other non-essential equipment as a means of access control.

Instruments can be configured so that when a user begins the reservation, NUCore sends a toggle signal and remotely switches on the power so the instrument can be used.  When the user ends their reservation (or the reservation ends) the power is switched off again.

The Daily View timeline page on the admin Reservations tab also queries the relays for status checks to show an up-to-date timeline of which instruments are available (relay is off) or occupied (relay is on).

Admin users can switch all relays on or off for a facility at once by visiting the Products/Insrtuments tab and looking for the buttons Turn all relays On/Off at the top of the Active Instruments list.

## How to configure
Set a value for Maximum (minutes) under Reservation Restrictions.

When editing an instrument, click the Timers & Relays tab, then select "Timer with relay" as the control mechanism.  A form will appear with more configuration options.  The fields under "Power Relay Information" are used to communicate with the relay.  The fields under "Ethernet Port" are used for reference only.

You can specify a value for Secondary outlet if you want two outlets to be toggled at the same time (perhaps controlling 2 monitors for a single instrument).

## Which models are supported
Synaccess Models: NP-02 and NP-02B
https://www.synaccess-net.com/np-02b

Dataprobe iPIO
https://dataprobe.com/ipio-8-ethernet-io/

https://pm.tablexi.com/issues/65431

## Dependencies
Synaccess:
https://github.com/tablexi/synaccess

Dataprobe:
`gem "dataprobe", path: "vendor/engines/dataprobe"`

## Known issues

### `NetBooter::Error: Error connecting to relay: execution expired`

This is a connectivity issue that is either because of erronious relay settings in NUCore, or some networking issue outside of NUCore.

First, check in NUCore to ensure the correct IP address and port have been provided -- the standard port is 80.

NUCore needs to make an HTTP connection to the relay. So, from the NUCore server, test to see if the relay's IP address & port respond to `ping` and `curl`. If you are able to `ping` the IP address but it does not respond to `curl`, there may be a firewall issue that needs to be addressed.

If the issue is only impacting 1 or 2 facilities, that is a good indication that the problem may be firewall related (not NUCore).
