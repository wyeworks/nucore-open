# frozen_string_literal: true

class AddPricePolicyUsageRateDaily < ActiveRecord::Migration[7.0]
  def change
    with_options(precision: 10, scale: 2) do
      add_column :price_policies, :usage_rate_daily, :decimal
      add_column :price_policies, :usage_subsidy_daily, :decimal
    end
  end
end
