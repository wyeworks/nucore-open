# frozen_string_literal: true

class AddReadAccessToFacilityUserPermissions < ActiveRecord::Migration[8.0]
  class FacilityUserPermission < ActiveRecord::Base
  end

  def up
    add_column :facility_user_permissions, :read_access, :boolean, default: false, null: false
    FacilityUserPermission.update_all(read_access: true)
  end

  def down
    remove_column :facility_user_permissions, :read_access
  end
end
