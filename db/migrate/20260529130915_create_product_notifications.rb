# frozen_string_literal: true

class CreateProductNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :product_notifications do |t|
      t.references :facility, null: false
      t.string :name
      t.string :notification_type, null: false
      t.integer :users_count, null: false, default: 0
      t.integer :reservation_days

      t.timestamps
    end

    create_join_table :product_notifications, :products do |t|
      t.index :product_notification_id
      t.index :product_id
    end
    create_join_table :product_notifications, :users do |t|
      t.index :product_notification_id
      t.index :user_id
    end
  end
end
