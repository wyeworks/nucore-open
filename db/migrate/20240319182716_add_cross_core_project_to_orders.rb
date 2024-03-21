# frozen_string_literal: true

class AddCrossCoreProjectToOrders < ActiveRecord::Migration[7.0]
  def change
    add_reference :orders, :cross_core_project, type: :integer, foreign_key: { to_table: :projects }
  end
end
