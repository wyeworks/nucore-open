# frozen_string_literal: true

class AddReadAccessToFacilityUserPermissions < ActiveRecord::Migration[8.0]
  def up
    add_column :facility_user_permissions, :read_access, :boolean, default: false, null: false
    execute "UPDATE facility_user_permissions SET read_access = true"
  end

  def down
    remove_column :facility_user_permissions, :read_access
  end
end
