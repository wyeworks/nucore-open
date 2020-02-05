# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

OrderStatus.create(name: "New")
OrderStatus.find_or_create_by(name: "New")
OrderStatus.find_or_create_by(name: "In Process")
OrderStatus.find_or_create_by(name: "Canceled")
OrderStatus.find_or_create_by(name: "Complete")
OrderStatus.find_or_create_by(name: "Reconciled")

Affiliate.OTHER

# TODO revisit in Rails 4. If you run `rake db:reset db:create db:migrate db:seed` as one step,
# it fails on not recognizing `is_internal`
PriceGroup.reset_column_information

[
  PriceGroup.create_with(is_internal: true, admin_editable: false).find_or_initialize_by(name: Settings.price_group.name.base),
  PriceGroup.create_with(is_internal: true, admin_editable: true).find_or_initialize_by(name: Settings.price_group.name.cancer_center),
  PriceGroup.create_with(is_internal: false, admin_editable: false).find_or_initialize_by(name: Settings.price_group.name.external),
].each_with_index do |price_group, index|
  next if price_group.name.blank? || price_group.persisted?
  price_group.display_order = index + 1
  price_group.save(validate: false)
end
