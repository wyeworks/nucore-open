# frozen_string_literal: true

class UpdateDecimalPrecision < ActiveRecord::Migration[4.2]

  def self.up
    change_column :schedule_rules, :discount_percent,    :decimal, precision: 10, scale: 2, null: false, default: 0

    change_column :price_policies, :usage_rate,          :decimal, precision: 10, scale: 2, null: true
    change_column :price_policies, :usage_subsidy,       :decimal, precision: 10, scale: 2, null: true
    change_column :price_policies, :reservation_rate,    :decimal, precision: 10, scale: 2, null: true
    change_column :price_policies, :reservation_subsidy, :decimal, precision: 10, scale: 2, null: true
    change_column :price_policies, :overage_rate,        :decimal, precision: 10, scale: 2, null: true
    change_column :price_policies, :overage_subsidy,     :decimal, precision: 10, scale: 2, null: true
    change_column :price_policies, :unit_cost,           :decimal, precision: 10, scale: 2, null: true
    change_column :price_policies, :unit_subsidy,        :decimal, precision: 10, scale: 2, null: true
    change_column :price_policies, :minimum_cost,        :decimal, precision: 10, scale: 2, null: true
    change_column :price_policies, :cancellation_cost,   :decimal, precision: 10, scale: 2, null: true

    change_column :order_details, :total_cost,           :decimal, precision: 10, scale: 2, null: true
    change_column :order_details, :total_subsidy,        :decimal, precision: 10, scale: 2, null: true
  end

  def self.down
    change_column :schedule_rules, :discount_percent,    :decimal, precision: 5, scale: 2, null: false, default: 0

    change_column :price_policies, :usage_rate,          :decimal, precision: 9, scale: 2, null: true
    change_column :price_policies, :usage_subsidy,       :decimal, precision: 9, scale: 2, null: true
    change_column :price_policies, :reservation_rate,    :decimal, precision: 9, scale: 2, null: true
    change_column :price_policies, :reservation_subsidy, :decimal, precision: 9, scale: 2, null: true
    change_column :price_policies, :overage_rate,        :decimal, precision: 9, scale: 2, null: true
    change_column :price_policies, :overage_subsidy,     :decimal, precision: 9, scale: 2, null: true
    change_column :price_policies, :unit_cost,           :decimal, precision: 9, scale: 2, null: true
    change_column :price_policies, :unit_subsidy,        :decimal, precision: 9, scale: 2, null: true
    change_column :price_policies, :minimum_cost,        :decimal, precision: 9, scale: 2, null: true
    change_column :price_policies, :cancellation_cost,   :decimal, precision: 9, scale: 2, null: true

    change_column :order_details, :total_cost,           :decimal, precision: 8, scale: 2, null: true
    change_column :order_details, :total_subsidy,        :decimal, precision: 8, scale: 2, null: true
  end

end
