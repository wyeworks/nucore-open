# frozen_string_literal: true

class AlterPricePoliciesChangePrecision < ActiveRecord::Migration[4.2]

  def up
    change_column :price_policies, :usage_rate, :decimal, precision: 12, scale: 4
    change_column :price_policies, :usage_subsidy, :decimal, precision: 12, scale: 4
  end

  def down
    change_column :price_policies, :usage_rate, :decimal, precision: 10, scale: 2
    change_column :price_policies, :usage_subsidy, :decimal, precision: 10, scale: 2
  end

end
