# frozen_string_literal: true

class AddPriceGroupDisplayOrder < ActiveRecord::Migration[4.2]

  def self.up
    add_column :price_groups, :display_order, :integer, precision: 38, scale: 0, default: 3, null: false
    pg = PriceGroup.unscoped.find_by(name: "Northwestern Customers")
    pg.update_attribute(:display_order, 1) unless pg.nil?

    pg = PriceGroup.unscoped.find_by(name: "External Customers")
    pg.update_attribute(:display_order, 2) unless pg.nil?
  end

  def self.down
    remove_column :price_groups, :display_order
  end

end
