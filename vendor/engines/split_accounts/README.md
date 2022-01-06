# Split Accounts

Splits Accounts is an engine that allows a user to charge a certain percentage
of a purchase to different accounts.

## Installation

Make sure the `gem "split_accounts",   "~> 0.0.1", path: "vendor/engines/split_accounts"`
line is enabled in `Gemfile`. Then ensure the `feature.split_accounts_on` in
`Settings.yml` is set to `true`.

## Notes

* Only global admins may create a Split Account. Other account admins and facility
    admins may edit the membership list.
* `SplitAccounts` expire when the earliest of its children expire.
* If you suspend a child account, the parent gets suspended as well. However, if you
    unsuspend a child account, the parent remains suspended. You must re-activate
    the parent account yourself.

## "Apply Remainder" Behavior

The costs are calculated by multiplying the cost of an order by the percentage of
each split. The result is then rounded down to the penny. We then add up each
accounts' amount; if there is a difference with the original amount, the difference
is applied to the account that has "Apply Remainder" selected.

### Simple Example:

_$10.51 order split between two 50/50 subaccounts_

`50% * $10.51 = $5.255`

We drop the last 5 so we have $5.25 and $5.25. There is a $0.01 remainder from
the total, so we apply that to the one with "Apply Remainder" set. One account will
be charged $5.25 and one will be charged $5.26.

### Complex Example

_Total: $10.50_

Accounts:

    * A: 33.34% with extra penny
    * B: 33.33%
    * C: 33.33%

That comes out to $3.5007, $3.49965, $3.49965. When we drop the fractional
pennies: $3.50, $3.49, $3.49.

There is a 2 cent remainder. That results in the accounts being charged the following:

    * A: $3.52
    * B: $3.49
    * C: $3.49

If the "Apply Remainder" flag were set on account B, the results would be slightly
more even:

    * A: $3.50
    * B: $3.51
    * C: $3.49
