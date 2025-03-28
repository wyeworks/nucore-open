# frozen_string_literal: true

class ChangeProductOrderNotificationRecipient < ActiveRecord::Migration[7.0]
  def up
    change_column :products, :order_notification_recipient, :string, limit: 1000
    rename_column :products, :order_notification_recipient, :order_notification_recipients
  end

  def down
    rename_column :products, :order_notification_recipients, :order_notification_recipient
    change_column :products, :order_notification_recipient, :string, limit: 255
  end
end
