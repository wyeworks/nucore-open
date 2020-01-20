# frozen_string_literal: true

class RemoveProductIdFromPricePolicies < ActiveRecord::Migration[4.2]

  def self.up
    remove_column :price_policies, :product_id
  end

  def self.down
    add_column :price_policies, :product_id, :integer, precision: 38, scale: 0, default: nil, null: true
  end

end
