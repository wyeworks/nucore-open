# frozen_string_literal: true

class AddDisputeCreditToOrderDetails < ActiveRecord::Migration[4.2]

  def self.up
    add_column :order_details, :dispute_resolved_credit, :decimal, null: true, precision: 10, scale: 2
  end

  def self.down
    remove_column :order_details, :dispute_resolved_credit
  end

end
