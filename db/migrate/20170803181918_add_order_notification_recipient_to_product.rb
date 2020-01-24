# frozen_string_literal: true

class AddOrderNotificationRecipientToProduct < ActiveRecord::Migration[4.2]

  def change
    add_column :products, :order_notification_recipient, :string, null: true
  end

end
