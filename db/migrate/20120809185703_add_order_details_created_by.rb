# frozen_string_literal: true

class AddOrderDetailsCreatedBy < ActiveRecord::Migration[4.2]

  def self.up
    add_column :order_details, :created_by, :integer

    OrderDetail.reset_column_information

    Order.all.each do |order|
      order.order_details.each { |detail| detail.update_attribute :created_by, order.created_by }
    end

    # oracle won't let us put a not null constraint on a new column for an existing, non-empty table
    change_column :order_details, :created_by, :integer, null: false
  end

  def self.down
    remove_column :order_details, :created_by
  end

end
