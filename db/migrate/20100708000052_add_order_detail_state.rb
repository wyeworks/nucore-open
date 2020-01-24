# frozen_string_literal: true

class AddOrderDetailState < ActiveRecord::Migration[4.2]

  def self.up
    change_table :order_details do |t|
      t.string :state, limit: 50
    end
  end

  def self.down
    remove_column :order_details, :state
  end

end
