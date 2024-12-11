How reservations work
=====================

Instruments have a time schedule where they can be reserved. A Reservation
generally refer to a user scheduling the use of the instrument but also can
refer to the instrument being offline or reserved for an administrative task.

Instruments are a type of Product which whose usage can be purchased by users
through Reservations. So whenever a new reservation is created, an order is
created or updated to include the Instrument as part of its order details with
a cost set according to the Instrument's characteristics and the reservation
duration.

How the cost is calculated from the duration depends on the Instrument's
pricing policy which can be one of three types:

1. Schedule Rule: charge per minute with fixed rate.
2. Duration: charge per minute with a stepped rate depending on the duration.
3. Schedule Rule (Daily Booking): charged per day with fixed rate.

The first two allow reservations to be defined on a per minute basis while the
third one is done in 24-hour blocks.

## Schedule Rules

They define the Instrument availability schedule.

Admins can define the time when an instrument is available for reservation. The
schedule rules for instruments are defined by specifying a start and end time
within the day and a set of weekdays on which the instrument is available. i.e.
from 9:00 to 17:00 from Monday to Friday.

One instrument can have several schedule rules defined although they cannot
have overlapping/conflicting time definitions.

## Reservations

Used for a time slot purchased by a user over an Instrument.

The `Reservation` model is inherited by `OfflineReservation` and
`AdminReservation` and they follow a STI pattern.

### Schedule Rule or Duration priced Instruments

Instruments can be reserved on a time slot if two conditions are satisfied:

1. The schedule rules allow *the full duration of that time slot*
2. There's no other reservation that overlaps that time slot for the instrument
   or the user making the reservation (for other instruments)

Both checks are verified during the `Reservation` model validation in the
module `Reservations::Validations`.

The first condition is implemented by checking if every minute in the time slot
is covered by a schedule rule, see `ScheduleRule::cover?`.

The second condition is verified on `Reservation#conflict_user_reservation` and
basically queries the DB to check if there's another record with those
conditions.

### Daily Booking priced Instruments

For these Instruments, a reservation is valid if:

1. The schedule rules allow *the start time of the time slot*
2. There's no other reservation that overlaps that time slot for the instrument
   or the user making the reservation (for other instruments)

The first condition is verified by checking if any schedule rule covers the
time slot start time, see `ScheduleRule::cover_time?`.

## OfflineReservation

Represents a time slot for the instrument being offline.

Offline Reservations are created by Admins by going to the "Reservations" admin
tab for an instrument and clicking: Mark Instrument Offline and then Bring
Instrument Online. These reservations cannot be scheduled and are not
restricted by schedule rules.

See `OfflineReservationsController`.

## AdminReservation

It's a time slot reserved by an Admin to prevent the Instrument from being
used.

This kind of reservations are created by Admins and prevent the instrument from
being reserved by users. They can be scheduled and are not restricted by
schedule rules.

See `FacilityReservationsController`.

## Find next available time

There are a few use cases where we need to find the next available time slot
for a given instrument and a duration. The use cases are:

- Preload the reservation form with a valid time slot
- Move an existing reservation to the nearest future date (Move up a
  reservation)

The code behind this lookup is in the class `NextAvailableReservationFinder`
which in turns call `Instrument#next_available_reservation` (defined in
`Products::SchedulingSupport`) which returns an unpersisted `Reservation`
object with start time and end time set to a valid slot.

The logic in `Instrument#next_available_reservation` attempts to find a time
slot of the given duration according to the schedule rules. For each day of the
week, it checks for each rule if it can find an available slot. The check for
each rule is done by the class `Product::SchedulingSupport::ReservationFinder`
which iterates over time querying the DB to check conflicts with other
reservations until a slot is found or a limit in the iterations is reached.

Note that there are some flaws on this logic: it's complex, the amount of DB
queries can be high, lacks schedule rules checks on `ReservationFinder` when
iterating over time (issue #162499).

The logic in charge of moving a reservation up uses
`Instrument#next_available_reservation` but called from
`Reservation#move_to_earliest` which basically find the closest future time
slot and assigns the time window to the self instance.
