# frozen_string_literal: true

class FlattenPricePolicyForeignKeys < ActiveRecord::Migration[4.2]

  def self.up
    add_column :price_policies, :product_id, :integer, after: :type
    PricePolicy.reset_column_information
    PricePolicy.all.each do |pp|
      pp.product_id = (pp.instrument_id || pp.service_id || pp.item_id)
      pp.save false
    end
    remove_column :price_policies, :instrument_id
    remove_column :price_policies, :service_id
    remove_column :price_policies, :item_id
  end

  def self.down
    add_column :price_policies, :item_id, :integer, after: :type
    add_column :price_policies, :service_id, :integer, after: :type
    add_column :price_policies, :instrument_id, :integer, after: :type
    PricePolicy.all.each do |pp|
      key = pp.type.gsub(/PricePolicy/, "").downcase
      pp.send(:"#{key}_id=", pp.product_id)
      pp.save false
    end
    remove_column :price_policies, :product_id
  end

end
