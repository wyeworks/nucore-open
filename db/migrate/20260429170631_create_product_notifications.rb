# frozen_string_literal: true

class CreateProductNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :product_notifications do |t|
      t.belongs_to :product, null: false
      t.string :notification_type, null: false
      t.string :recipient_source
      t.text :data

      t.timestamps
    end

    add_index :product_notifications, [:product_id, :notification_type]
  end
end
