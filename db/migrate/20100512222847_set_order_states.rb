# frozen_string_literal: true

class SetOrderStates < ActiveRecord::Migration[4.2]

  def self.up
    Order.where(ordered_at: nil).update_all(state: "new")
    Order.where.not(ordered_at: nil).update_all(state: "purchased")
  end

  def self.down
    Order.update_all(state: nil)
  end

end
