# UmassCorum

This engine is for custom configuration of UMass's implementation.

## What it does

* UMass Branding
* Speed Type Validation
* Connect to OWL Research Safety API for Research Safety

## Speed Type Validation

UMass uses the concept of a "SpeedType" which is a shorthand for a full chartstring, which can
be thought of as account numbers within the financial system.

A chartstring at UMass includes a few components:

  * Fund
  * Department
  * Program
  * Class
  * Project/Grant

In order to add a SpeedType into Corum, we want to first validate that is is an
actual SpeedType in the financial system and that it is currently active.

When a user wishes to add a SpeedType, we perform these steps:

  1. Basic format validation: is it 6 numbers long?
  1. Make a query against the SpeedType API (provided by the school)
  1. If the SpeedType is invalid or inactive, provide an error to the user
  1. If the SpeedType is valid, store the response in the `api_speed_types` table
  1. Create the NUcore/Corum `Account` or `FacilityAccount` record

There is a nightly job managed by UMass's IT team that does the following:

  1. Downloads the list of active speed types from the President’s office
  1. Updates any existing records in `api_speed_types` that have changed
  1. Marks any speed types which have become inactive with `active = 0` and `date_removed`,
     as well as `error_desc`
  1. Inserts new speed types

## SSL Certificates

The SSL certificate we've installed is valid for the following hostnames. There are additional names not currently in use if we need to add additional servers later.

```
corum.umass.edu
corum-test.umass.edu
corum-dev.umass.edu
ials-core-web-prod-01.it.umass.edu
ials-core-web-prod-02.it.umass.edu
ials-core-web-prod-03.it.umass.edu
ials-core-web-prod-04.it.umass.edu
ials-core-web-test-01.it.umass.edu
ials-core-web-test-02.it.umass.edu
ials-core-web-dev-01.it.umass.edu
ials-core-web-dev-02.it.umass.edu
```
