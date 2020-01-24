# frozen_string_literal: true

class AddPriceGroupTypeToPriceGroups < ActiveRecord::Migration[4.2]

  def self.up
    add_column :price_groups, :is_internal, :boolean, null: false
  end

  def self.down
    remove_column :price_groups, :is_internal
  end

end
