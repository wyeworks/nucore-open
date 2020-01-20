# frozen_string_literal: true

class AdjustOrder < ActiveRecord::Migration[4.2]

  def self.up
    change_table :orders do |t|
      t.change :account_id, :integer, null: true
      t.change :ordered_at, :datetime, null: true
    end
  end

  def self.down
    say "destroying all existing orders"
    Order.destroy_all
    change_table :orders do |t|
      t.change :account_id, :integer, null: false
      t.change :ordered_at, :datetime, null: false
    end
  end

end
