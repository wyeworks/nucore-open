# frozen_string_literal: true

class AddReserveDaysFieldsToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :min_reserve_days, :integer
    add_column :products, :max_reserve_days, :integer
  end
end
