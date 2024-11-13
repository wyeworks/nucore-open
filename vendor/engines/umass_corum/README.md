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

There is a job managed by UMass's IT team that runs daily at 7:30am ET.  It does the following:

  1. Downloads the list of active speed types from the President’s office
  1. Updates any existing records in `api_speed_types` that have changed
  1. Marks any speed types which have become inactive with `active = 0` and `date_removed`,
     as well as `error_desc`
  1. Inserts new speed types

There is a `SpeedTypeSynchronizer` job that runs daily at 8:45 ET.  It does the following:
  1. Updates the SpeedTypeAccounts `expires_at` dates to match the ApiSpeedType `date_removed`

## Price Groups

  * Internal (UMass affiliated)
    * Anyone at UMass Amherst
  * Other academic (UMass Affiliated)
    * This would be for the other UMass Campuses & 4 colleges (Amherst, Holyoke, Hampshire, and Smith) who get treated as
    internal customers for pricing, but likely won’t have speedtypes we can charge against
  * Other academic (Non-UMass Affiliated)
      * Any academic institutions beyond those I mentioned who would be receiving a surcharge
  * External
    * All non academic external users

## Users

Most users in Corum should log in with their UMass NetID. This is handled through
SAML using our [saml_authentication](../saml_authentication/README.md) engine as the Service
Provider (SP) and the school-managed Shibboleth Identity Provider (IdP).

Only users external to UMass who do not have a NetID should be given a username and password. Users must first be created in Corum before they are able to log in (even if they have a NetID).

We update users' attributes like email address and first/last name as part of the SAML
login process. There is also a nightly job managed by UMass IT that updates the users'
attributes.

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
