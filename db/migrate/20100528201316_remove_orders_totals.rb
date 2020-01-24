# frozen_string_literal: true

class RemoveOrdersTotals < ActiveRecord::Migration[4.2]

  def self.up
    remove_column :orders, :total_cost
    remove_column :orders, :total_subsidy
    remove_column :orders, :total
  end

  def self.down
    add_column :orders, :total_cost,    :decimal, precision: 8, scale: 2, null: true
    add_column :orders, :total_subsidy, :decimal, precision: 8, scale: 2, null: true
    add_column :orders, :total,         :decimal, precision: 8, scale: 2, null: true

    execute "UPDATE orders SET total_cost = 0"
    execute "UPDATE orders SET total_subsidy = 0"
    execute "UPDATE orders SET total = 0"

    change_column :orders, :total_cost,    :decimal, precision: 8, scale: 2, null: false
    change_column :orders, :total_subsidy, :decimal, precision: 8, scale: 2, null: false
    change_column :orders, :total,         :decimal, precision: 8, scale: 2, null: false
  end

end
