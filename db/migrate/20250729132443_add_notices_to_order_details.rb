# frozen_string_literal: true

class AddNoticesToOrderDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :order_details, :notices, :string
    add_column :order_details, :problems, :string
  end
end
