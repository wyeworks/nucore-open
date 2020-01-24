# frozen_string_literal: true

class AddQuantityLockToExternalServiceReceivers < ActiveRecord::Migration[4.2]

  def change
    add_column :external_service_receivers, :manages_quantity, :boolean, default: false, null: false
  end

end
