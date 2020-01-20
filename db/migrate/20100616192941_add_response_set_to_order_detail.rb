# frozen_string_literal: true

class AddResponseSetToOrderDetail < ActiveRecord::Migration[4.2]

  def self.up
    add_column :order_details, :response_set_id, :integer
  end

  def self.down
    remove_column :order_details, :response_set_id
  end

end
