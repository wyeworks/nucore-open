# Sanger Sequencing

[TODO Explain feature]

## Enabling Sanger Sequencing

### Turn on the engine

Make sure the engine is enabled in your `Gemfile`

```ruby
gem "sanger_sequencing", path: "vendor/engines/sanger_sequencing"
```

### Enable the admin-tab for the facility

There is not currently an interface for enabling the admin-side management. In order
to enable the "Sanger" top-level tab for a facility, set the
`sanger_sequencing_enabled` field to `true`/`1` on the facility in the `facilities`
table. From the rails console, you can do this by:

```ruby
Facility.find_by(url_name: "facility-name").update_attributes(sanger_sequencing_enabled: true)
```

### Set up the order form for a service

* Create a new service from the Products tab, including Pricing
* Under "Order Forms", add a new Online Order Form
* Use the URL `https://[yourdomain]/sanger_sequencing/submissions/new` and click "Add"
* Click "Activate" to turn it on

### Enable Fragment Analysis Well Plate Creation

* Create a Fragment Analysis Product
* Add a row "fragment" under `sanger_sequencing_product_groups` that maps to
  the new product.

  ```ruby
  SangerSequencing::ProductGroup.create(product: product, group: "fragment")
  ```

A product can only be part of a single group. If it is not part of a group,
it falls back to a "default" group, which is the standard Sanger Sequencing.
