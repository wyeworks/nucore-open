# frozen_string_literal: true

class UpdateCrossCoreOrderingAvailableInProducts < ActiveRecord::Migration[7.0]
  class Product < ApplicationRecord; end

  def up
    change_column :products, :cross_core_ordering_available, :boolean, default: false, null: false

    Product.update_all(cross_core_ordering_available: false)
  end

  def down
    change_column :products, :cross_core_ordering_available, :boolean, default: true, null: false
  end
end
