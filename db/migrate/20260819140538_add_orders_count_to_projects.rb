# frozen_string_literal: true

class AddOrdersCountToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :orders_count, :integer, default: 0, null: false
  end
end
