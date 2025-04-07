# frozen_string_literal: true

class AddOrderDetailsUnrecoverableNote < ActiveRecord::Migration[7.0]
  def change
    add_column :order_details, :unrecoverable_note, :string
  end
end
