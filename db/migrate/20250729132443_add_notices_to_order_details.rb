# frozen_string_literal: true

class AddNoticesToOrderDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :order_details, :notice_keys, :string
    add_column :order_details, :problem_keys, :string
  end
end
