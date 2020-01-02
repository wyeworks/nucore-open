# NuResearchSafety

Interfaces with a Northwestern-provided API to provide information on the status of users' research safety certifications.

Certificates of interest may be added through Global Settings and are stored in the `certificates` table. Certificates
may be associated with specific products, which will then require the purchaser to have a currently valid status for
that certificate before they are able to purchase. Orders on behalf of users by admins will not check certificate
status.

Engine is currently specific to Northwestern and only available in nucore-nu.

## Installation

Make sure the `gem "nu_research_safety", path: "vendor/engines/nu_research_safety", group: [:development, :stage, :test]`
line is enabled in `Gemfile`.
