# frozen_string_literal: true

class AddPricingModeToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :pricing_mode, :string, null: false, default: "Schedule Rule"
  end
end
