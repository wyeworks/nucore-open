# frozen_string_literal: true

class AddCancellationNotificationToProduct < ActiveRecord::Migration[5.0]
  def change
    change_table :products do |t|
      t.text :cancellation_email_recipients
    end
  end
end
