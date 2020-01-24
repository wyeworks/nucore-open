# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[4.2]

  def self.up
    create_table :orders do |t|
      t.references :facility, null: false
      t.references :account,  null: false
      t.foreign_key :accounts
      t.references :user, null: false
      t.integer :created_by, null: false
      t.references :price_group, null: false
      t.decimal :total_cost,    precision: 8, scale: 2, null: false
      t.decimal :total_subsidy, precision: 8, scale: 2, null: false
      t.decimal :total,         precision: 8, scale: 2, null: false

      t.timestamps null: false
      t.datetime :ordered_at, null: false
    end
  end

  def self.down
    drop_table :orders
  end

end
