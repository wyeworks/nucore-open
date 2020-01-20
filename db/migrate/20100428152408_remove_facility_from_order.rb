# frozen_string_literal: true

class RemoveFacilityFromOrder < ActiveRecord::Migration[4.2]

  def self.up
    change_table :orders do |t|
      t.remove :facility_id
      t.change :price_group_id, :integer, null: true
    end

    change_table :order_details do |t|
      t.change :price_policy_id, :integer, null: true
    end
  end

  def self.down
    say "destroying all existing orders"
    Order.destroy_all
    change_table :orders do |t|
      t.references :facility, null: false
      t.foreign_key :facility
      t.change :price_group_id, :integer, null: false
    end

    change_table :order_details do |t|
      t.change :price_policy_id, :integer, null: false
    end
  end

end
