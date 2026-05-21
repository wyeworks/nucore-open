# frozen_string_literal: true

class AddReportingToFacilityUserPermissions < ActiveRecord::Migration[8.0]
  def change
    add_column :facility_user_permissions, :reporting, :boolean, default: false, null: false
  end
end
