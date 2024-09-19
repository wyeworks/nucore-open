# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

OrderStatus.find_or_create_by(name: "New")
OrderStatus.find_or_create_by(name: "In Process")
OrderStatus.find_or_create_by(name: "Canceled")
OrderStatus.find_or_create_by(name: "Complete")
OrderStatus.find_or_create_by(name: "Reconciled")
OrderStatus.find_or_create_by(name: "Unrecoverable")

Affiliate.OTHER

# TODO revisit in Rails 4. If you run `rake db:reset db:create db:migrate db:seed` as one step,
# it fails on not recognizing `is_internal`
PriceGroup.reset_column_information

[
  { name: Settings.price_group.name.base, is_internal: true, admin_editable: false },
  { name: Settings.price_group.name.cancer_center, is_internal: true, admin_editable: true },
  { name: Settings.price_group.name.external, is_internal: false, admin_editable: false },
].each do |pg_data|
  next if pg_data[:name].blank?

  PriceGroup.setup_global(
    name: pg_data[:name],
    is_internal: pg_data[:is_internal],
    admin_editable: pg_data[:admin_editable]
  )
end

UmassCorum::Engine.load_seed
