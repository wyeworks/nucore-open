# frozen_string_literal: true

class MakeOrderDetailOrderStatusNullable < ActiveRecord::Migration

  def self.up
    change_column :order_details, :order_status_id, :integer, null: true
  end

  def self.down
    change_column :order_details, :order_status_id, :integer, null: false
  end

end
