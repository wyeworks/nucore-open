# frozen_string_literal: true

class AddKioskEnabledToFacilities < ActiveRecord::Migration[5.2]
  def change
    change_table :facilities do |t|
      t.boolean :kiosk_enabled
    end
  end
end
