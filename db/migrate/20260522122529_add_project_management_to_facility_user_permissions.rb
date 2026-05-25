# frozen_string_literal: true

class AddProjectManagementToFacilityUserPermissions < ActiveRecord::Migration[8.0]
  def change
    add_column :facility_user_permissions, :project_management, :boolean, default: false, null: false
  end
end
