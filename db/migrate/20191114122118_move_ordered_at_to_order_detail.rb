# frozen_string_literal: true

class MoveOrderedAtToOrderDetail < ActiveRecord::Migration[5.0]
  def up
    change_table :order_details do |t|
      t.datetime :ordered_at
    end

    execute NUCore::Database.oracle? ? oracle_up : mysql_up

    change_table :orders do |t|
      t.remove :ordered_at
    end
  end

  def down
    change_table :orders do |t|
      t.datetime :ordered_at, after: :updated_at
    end

    execute <<-SQL
        UPDATE orders
        SET orders.ordered_at = (
          SELECT MAX(order_details.ordered_at)
          FROM order_details
          WHERE order_details.order_id = orders.id
        )
      SQL

    change_table :order_details do |t|
      t.remove :ordered_at
    end
  end

  def mysql_up
    <<-SQL
      UPDATE order_details
      JOIN orders
      ON orders.id = order_details.order_id
      SET order_details.ordered_at = orders.ordered_at
    SQL
  end

  def oracle_up
    <<-SQL
      UPDATE
      (SELECT orders.ordered_at as orders_ordered_at, order_details.ordered_at as order_details_ordered_at
       FROM order_details
       INNER JOIN orders
       ON order_details.order_id = orders.id
      ) t
      SET t.order_details_ordered_at = t.orders_ordered_at
    SQL
  end
end
