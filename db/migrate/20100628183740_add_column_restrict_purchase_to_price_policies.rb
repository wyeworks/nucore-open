# frozen_string_literal: true

class AddColumnRestrictPurchaseToPricePolicies < ActiveRecord::Migration

  def self.up
    add_column :price_policies, :restrict_purchase, :boolean, null: true
  end

  def self.down
    remove_column :price_policies, :restrict_purchase
  end

end
