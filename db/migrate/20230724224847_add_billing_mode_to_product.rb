# frozen_string_literal: true

class AddBillingModeToProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :billing_mode, :string, null: false, default: "Default"
  end
end
