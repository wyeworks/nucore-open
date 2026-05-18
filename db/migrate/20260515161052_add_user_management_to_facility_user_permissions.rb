# frozen_string_literal: true

class AddUserManagementToFacilityUserPermissions < ActiveRecord::Migration[8.0]

  def change
    add_column :facility_user_permissions, :user_management, :boolean, default: false, null: false
  end

end
