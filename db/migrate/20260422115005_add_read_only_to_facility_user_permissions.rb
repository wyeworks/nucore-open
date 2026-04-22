class AddReadOnlyToFacilityUserPermissions < ActiveRecord::Migration[8.0]
  def change
    add_column :facility_user_permissions, :read_only, :boolean, default: false, null: false
  end
end
