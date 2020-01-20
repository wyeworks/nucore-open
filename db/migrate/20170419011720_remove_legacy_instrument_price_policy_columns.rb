# frozen_string_literal: true

class RemoveLegacyInstrumentPricePolicyColumns < ActiveRecord::Migration[4.2]

  COLUMNS = {
    usage_mins: [:integer, after: :usage_rate],
    reservation_rate: [:decimal, precision: 12, scale: 4, after: :usage_mins],
    reservation_subsidy: [:decimal, precision: 10, scale: 2, after: :usage_subsidy],
    reservation_mins: [:integer, after: :reservation_rate],
    overage_rate: [:decimal, precision: 12, scale: 4, after: :reservation_mins],
    overage_subsidy: [:decimal, precision: 10, scale: 2, after: :reservation_subsidy],
    overage_mins: [:integer, after: :overage_rate],
  }.freeze

  def up
    add_column :price_policies, :legacy_rates, :string

    # Store the old attributes in a JSON-formatted legacy_rates column
    InstrumentPricePolicy.where.not(usage_mins: nil).find_each do |ipp|
      attributes = ipp.attributes.slice(*COLUMNS.keys.map(&:to_s))
      ipp.update_column(:legacy_rates, attributes.to_json)
    end

    COLUMNS.keys.each do |key|
      remove_column :price_policies, key
    end
  end

  def down
    COLUMNS.each do |key, options|
      add_column :price_policies, key, *options
    end

    PricePolicy.reset_column_information

    InstrumentPricePolicy.where.not(legacy_rates: nil).find_each do |ipp|
      ipp.assign_attributes(JSON.parse(ipp.legacy_rates))
      ipp.save(validate: false)
    end

    remove_column :price_policies, :legacy_rates
  end

end
