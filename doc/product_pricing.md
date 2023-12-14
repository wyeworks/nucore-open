# Product Pricing
## All products
### Price rules
Products are assigned to price rules which allow setting rates associated with different price groups, which can either be internal or external. Based on the user's price group and the rate set for it in the product price rules, the final charge will be different.

#### Internal
For internal price groups there is a base rate. An adjustment amount can be configured for other internal price groups. This amount will be subtracted from the base rate.

#### External
External price groups have their own rates and adjustments cannot be set.

### Manual adjustment by admin
In case an order needs to be charged a different sum, an admin can navigate to the Billing section and update the Price manually. It's required to also enter a pricing note.

In the Order Detail view there's a button to Recalculate pricing, which returns the expected price based on the pricing rules.

## Instrument Pricing

Instruments are charged at a per-minute rate.

### Charge for

#### Reservation

Users are charged for the length of their reservation.

_Example_

Reservation 1-2pm

Result: User will always be charged 60 minutes, no matter the actual usage.

#### Usage

Users are charged for the length of time they actually used the instrument.

This should be used in conjunction with either "Timer without relay" or "Timer with relay"
control mechanism set on the Instrument detail edit screen.

_Examples_

Reservation 1-2pm

Usage: 1:15-1:45pm
Result: User is charged for 30 minutes

Usage: 1:00-2:15pm
Result: User is charged for 75 minutes

Usage: 1:15-2:15pm
Result: User is charged for 60 minutes

#### Overage

Users are charged for the length of their reservation plus any additional time spent
using the instrument after the end of the reservation.

This should be used in conjunction with either "Timer without relay" or "Timer with relay"
control mechanism set on the Instrument detail edit screen.

_Examples_

Reservation 1-2pm

Usage: 1:15-1:45pm
Result: User is charged for 60 minutes (the reservation length)

Usage: 1:00-2:15pm
Result: User is charged for 75 minutes (reservation plus 15 minutes of overage)

Usage: 1:15-2:15pm
Result: User is charged for 75 minutes (reservation plus 15 minutes of overage)

### Pricing mode
#### Schedule rule/price group based
Schedule rules state what days and times an instrument is available for reservation.

When using this Pricng mode, the user will pay an hourly rate defined by the Price Group they belong to.  Admins can set a percentage discount for each global Price Group during the times defined by each schedule rule.

#### Duration based
In this mode, there are up to 4 rates for each price policy. These rates apply to a given step, which is defined by setting a Rate start (hr). Price policies can either have no steps defined (just the usage rate) or all of them.

The first step, also called the "Initial Rate", will always start at 0 hours and its rate will be price policy's `usage_rate`. Note: This step is not created in the DB as a Rate Start, it is inferred from the price policy record.

Step hourly rate for non-base internal groups is calculated as `Base step rate - step adjustment`.  See examples below for more info.

The amount of hours the user should be charged for is split in these steps.

_Example_
|                 | Initial Rate | Step 2              | Step 3             | Step 4             |
|-----------------|--------------|---------------------|--------------------|--------------------|
| Price Group     | 0	           | Rate Start (hr): 2	 | Rate Start (hr): 5	| Rate Start (hr): 7 |
|-----------------|--------------|---------------------|--------------------|--------------------|
| Base Rate       | 50	         | Rate per hr: 45     | Rate per hr: 40    |	Rate per hr: 39    |
| Other internal  | 5     	     | Adjustment:   8	   | Adjustment:  10	  | Adjustment:  12    |
| External        | 65           | Rate per hr: 62	   | Rate per hr: 60    | Rate per hr: 60    |
| Other External  | 70           | Rate per hr: 64	   | Rate per hr: 62	  | Rate per hr: 58    |

In this example, users that are in the Base Rate Price Group will pay $50/hr for the first 2 hours, $45/hr for the next 3 hours (2-5), $40/hr for the next 2 hours (5-7), and $39/hr for all the rest (7+ hours).

Reservation for 10 hours:
  2 * 50
+ 3 * 45
+ 2 * 40
+ 3 * 39
= 100 + 135 + 80 + 117 = 432

On the other hand, users in Other Internal Price Group will have an adjustment of $5/hr for the first 2 hours, $8/hr for the next 3 hours (2-5), $10/hr for the next 2 hours (5-7), and $12/hr for the rest (7+ hours).

Reservation for 10 hours:
  2 * (50 - 5)
+ 3 * (45 - 8)
+ 2 * (40 - 10)
+ 3 * (39 - 12)
= 90 + 74 + 60 + 81 = 305

### Cancel/reservation charges
Admins can set a Reservation Cost in the price rule, which is only invoked if the user fails to cancel their reservation within a set time window. If no window is set, cancelation charges are applied regardless of the closeness to the reservation start time.
