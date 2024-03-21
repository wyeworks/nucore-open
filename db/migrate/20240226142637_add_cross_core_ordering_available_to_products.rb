# frozen_string_literal: true

class AddCrossCoreOrderingAvailableToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :cross_core_ordering_available, :boolean, default: true, null: false
  end
end
