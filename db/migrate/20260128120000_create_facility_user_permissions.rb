# frozen_string_literal: true

class CreateFacilityUserPermissions < ActiveRecord::Migration[8.0]

  def change
    create_table :facility_user_permissions do |t|
      t.references :user, null: false, type: :integer, foreign_key: true
      t.references :facility, null: false, type: :integer, foreign_key: true

      t.boolean :product_management, default: false, null: false
      t.boolean :product_pricing, default: false, null: false
      t.boolean :order_management, default: false, null: false
      t.boolean :price_adjustment, default: false, null: false
      t.boolean :billing_send, default: false, null: false
      t.boolean :billing_journals, default: false, null: false
      t.boolean :instrument_management, default: false, null: false
      t.boolean :assign_permissions, default: false, null: false

      t.timestamps
    end

    add_index :facility_user_permissions, [:user_id, :facility_id], unique: true
  end

end
