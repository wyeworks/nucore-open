# frozen_string_literal: true

class AddAccountManagementGranularPermission < ActiveRecord::Migration[8.0]
  def change
    add_column :facility_user_permissions, :account_management, :boolean, null: false, default: false
  end
end
