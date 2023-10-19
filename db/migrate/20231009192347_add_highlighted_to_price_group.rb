# frozen_string_literal: true

class AddHighlightedToPriceGroup < ActiveRecord::Migration[7.0]
  def change
    add_column :price_groups, :highlighted, :boolean, null: false, default: false
  end
end
