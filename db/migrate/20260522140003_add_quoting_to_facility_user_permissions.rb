# frozen_string_literal: true

class AddQuotingToFacilityUserPermissions < ActiveRecord::Migration[8.0]
  def change
    add_column :facility_user_permissions, :quoting, :boolean, default: false, null: false
  end
end
