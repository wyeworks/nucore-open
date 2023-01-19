# Research Safety Adapters

You can specify an adapter Class to facilitate API lookups for checking the status of user research safety certificate records.  The class name needs to be specified in `settings.yml`, either directly or via the `"RESEARCH_SAFETY_ADAPTER_CLASS"` ENV variable.
If nothing is specified, the default `ResearchSafetyAlwaysCertifiedAdapter` class is used.

An adapter class should be set up to accept a User object on initialization and implement a `certified?` method which accepts a `certificate` argument and returns a boolean value.

## SciShield integration

UMass and OSU make use of a SciShield API to fetch Research Safety Certificates:

* [`ScishieldApiAdapter`](../app/services/research_safety_adapters/scishield_api_adapter.rb)
* [`ScishieldApiClient`](../app/services/research_safety_adapters/scishield_api_client.rb)
* [BioRaft/SciShield API docs](https://pm.tablexi.com/issues/160883) (these are proprietary, so cannot be shared publicly)

### Known issue with system time sync

If the hardware clock drifts even 1 second from system time, API requests will fail:

```
403 Forbidden: This route can only be accessed by authenticated users.
```

All the servers have been set up to sync hardware clocks to system time with [`ntp`](https://thebackroomtech.com/2019/01/17/configure-centos-to-sync-with-ntp-time-servers/)


However, if you are getting the `403` response and have checked the JWT token is valid, you may need to debug the time sync.  After ensuring the sync service is up and running, you may also need to manually set the hardware clock to the current system time.  Log in as root, then try the following:

```
# check current time settings
timedatectl

# http://woshub.com/centos-set-date-time-timezone-ntp/
# check status of the sync service
service ntpd status

# Start/enable the sync service if needed
systemctl start ntpd.service
systemctl enable ntpd.service

# set the hardware clock to the current system time
hwclock -w
```
