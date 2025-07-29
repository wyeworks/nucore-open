# frozen_string_literal: true

class AddStatusBadgesToOrderDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :order_details, :status_badges, :string
  end
end
