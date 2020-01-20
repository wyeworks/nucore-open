# frozen_string_literal: true

class AddOrderNotificationRecipientToFacility < ActiveRecord::Migration[4.2]

  def change
    add_column :facilities, :order_notification_recipient, :string, null: true
  end

end
