# frozen_string_literal: true

class AddAdminCanSkipToExternalServices < ActiveRecord::Migration[8.0]
  def change
    add_column :external_services, :admin_can_skip, :boolean, default: false, null: false
  end
end
