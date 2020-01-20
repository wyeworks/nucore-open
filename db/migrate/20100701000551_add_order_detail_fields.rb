# frozen_string_literal: true

class AddOrderDetailFields < ActiveRecord::Migration[4.2]

  def self.up
    change_table :order_details do |t|
      t.integer   :account_id
      t.string    :status, limit: 50
      t.datetime  :dispute_at
      t.string    :dispute_reason, limit: 200
      t.datetime  :dispute_resolved_at
      t.string    :dispute_resolved_reason, limit: 200
      t.timestamps
    end
  end

  def self.down
    remove_column :order_details, :account_id
    remove_column :order_details, :status
    remove_column :order_details, :dispute_at
    remove_column :order_details, :dispute_reason
    remove_column :order_details, :dispute_resolved_at
    remove_column :order_details, :dispute_resolved_reason
    remove_column :order_details, :updated_at
    remove_column :order_details, :created_at
  end

end
