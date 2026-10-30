# frozen_string_literal: true

class AddFullCostCancellationToPricePolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :price_policies, :full_price_cancellation, :boolean, default: false, null: false
  end
end
