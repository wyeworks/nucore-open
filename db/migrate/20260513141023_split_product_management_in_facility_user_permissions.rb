# frozen_string_literal: true

class SplitProductManagementInFacilityUserPermissions < ActiveRecord::Migration[8.0]

  class FacilityUserPermission < ActiveRecord::Base
  end

  def up
    add_column :facility_user_permissions, :product_creation, :boolean, default: false, null: false
    add_column :facility_user_permissions, :product_edition, :boolean, default: false, null: false

    FacilityUserPermission.where(product_management: true)
                          .update_all(product_creation: true, product_edition: true)

    remove_column :facility_user_permissions, :product_management
  end

  def down
    add_column :facility_user_permissions, :product_management, :boolean, default: false, null: false

    FacilityUserPermission.where("product_creation = ? OR product_edition = ?", true, true)
                          .update_all(product_management: true)

    remove_column :facility_user_permissions, :product_creation
    remove_column :facility_user_permissions, :product_edition
  end

end
