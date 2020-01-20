# frozen_string_literal: true

class ChangePricePolicies < ActiveRecord::Migration[4.2]

  def self.up
    change_table :price_policies do |t|
      t.references :product
    end
  end

  def self.down
    remove_column :price_policies, :product_id
  end

end
