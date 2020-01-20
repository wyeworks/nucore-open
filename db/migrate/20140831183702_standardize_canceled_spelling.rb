# frozen_string_literal: true

class StandardizeCanceledSpelling < ActiveRecord::Migration[4.2]

  def up
    ActiveRecord::Base.transaction do
      change_spelling(OrderDetail, :state, "cancelled", "canceled")
      change_spelling(OrderDetail, :state, "super cancelled", "super canceled")
      change_spelling(OrderStatus, :name, "Cancelled", "Canceled")
      change_spelling(OrderStatus, :name, "Super Cancelled", "Super Canceled")
    end
  end

  def down
    ActiveRecord::Base.transaction do
      change_spelling(OrderDetail, :state, "canceled", "cancelled")
      change_spelling(OrderDetail, :state, "super canceled", "super cancelled")
      change_spelling(OrderStatus, :name, "Canceled", "Cancelled")
      change_spelling(OrderStatus, :name, "Super Canceled", "Super Cancelled")
    end
  end

  def change_spelling(model, property, from, to)
    model.where(property => from).update_all(property => to)
  end

end
