# frozen_string_literal: true

class AddParentPriceGroupIdToPriceGroups < ActiveRecord::Migration[8.0]
  def change
    add_reference :price_groups, :parent_price_group, type: :integer, foreign_key: { to_table: :price_groups }, null: true
  end
end
