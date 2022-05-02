# Recurring Tasks

There are some tasks that need to happen regularly, at 1 or 5 minute intervals.  These are currently all related to reservation management.  The list of recurring tasks is listed in `RecurringTaskConfig`, and managed by a daemon process (see [**HOWTO_daemons.txt**](./HOWTO_daemons.txt) for more information).

The `recurring_tasks` process should only run on one server per environment.   Set `RECURRING=true` in the environment (`.bashrc` for example) to configure which servers should run these tasks.

You can add or remove items from the list from your school-specific engine like so:
```ruby
RecurringTaskConfig.recurring_tasks << [SecureRooms::AutoOrphanOccupancy, :perform, 5]
```

## Examples of existing functionality

### Once per minute
- `InstrumentOfflineReservationCanceler`

  * Place a reservation for an instrument, then take that instrument offline.  The reservation should get cancelled within a minute or so of the reservation start time.

- `AdminReservationExpirer`

  * Place an admin hold on an instrument.  The hold should be removed from the calendar within a minute of its end time.

- `AutoCanceler`

  * Set a value of 1 for "Automatic Cancellation (minutes)", place a reservation and do not start it.  The unstarted reservation should be canceled 1 minute after the start time.

### Every 5 minutes
- `AutoExpireReservation`

  * Place a reservation for an instrument that has a relay and charges for Usage or Overage.  At 12 hours past the end time, the reservation should be moved to the problem queue.

- `EndReservationOnly`

  * Place a reservation for an instrument that charges for "Reservation only".  When the reservation end time is reached, the reservation should get completed automatically.

- `AutoLogout`

  * Place a reservation for an instrument that has a relay with the Auto-Relay Shutoff? checkbox checked and 15 minutes for "minutes after the reservation is scheduled to end".  15 minutes after the reservation ends, the reservation should be moved to the problem queue.
