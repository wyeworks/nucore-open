# frozen_string_literal: true

class AddBulkEmailToFacilityUserPermissions < ActiveRecord::Migration[8.0]
  def change
    add_column :facility_user_permissions, :bulk_email, :boolean, default: false, null: false
  end
end
