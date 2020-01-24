# frozen_string_literal: true

class IncreaseDecimalPrecision < ActiveRecord::Migration[4.2]

  def up
    change_column :price_policies, :overage_rate, :decimal, precision: 12, scale: 4
    change_column :price_policies, :reservation_rate, :decimal, precision: 12, scale: 4
  end

  def down
    change_column :price_policies, :overage_rate, :decimal, precision: 10, scale: 2
    change_column :price_policies, :reservation_rate, :decimal, precision: 10, scale: 2
  end

end
