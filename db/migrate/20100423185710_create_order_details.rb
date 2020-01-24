# frozen_string_literal: true

class CreateOrderDetails < ActiveRecord::Migration[4.2]

  def self.up
    create_table :statements do |t|
    end

    create_table :reservations do |t|
    end

    create_table :order_details do |t|
      t.references :order, null: false
      t.foreign_key :orders

      t.references :product, null: false
      t.foreign_key :products

      t.references :reservation
      t.foreign_key :reservations

      t.integer :quantity, null: false

      t.references :price_policy, null: false
      t.foreign_key :price_policies

      t.decimal :unit_cost,     precision: 8, scale: 2, null: false
      t.decimal :unit_subsidy,  precision: 8, scale: 2, null: false
      t.decimal :total_cost,    precision: 8, scale: 2, null: false
      t.decimal :total_subsidy, precision: 8, scale: 2, null: false

      t.references :order_status
      t.foreign_key :order_statuses

      t.integer :assigned_user_id

      t.references :statement
      t.foreign_key :statements
    end
  end

  def self.down
    drop_table :order_details
    drop_table :reservations
    drop_table :statements
  end

end
