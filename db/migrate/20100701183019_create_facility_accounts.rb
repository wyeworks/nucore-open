# frozen_string_literal: true

class CreateFacilityAccounts < ActiveRecord::Migration[4.2]

  def self.up
    create_table :facility_accounts do |t|
      t.references :facility,       null: false
      t.string     :account_number, null: false, limit: 50
      t.boolean    :is_active,      null: false
      t.integer    :created_by,     null: false
      t.datetime   :created_at,     null: false
    end
    add_foreign_key :facility_accounts, :facilities, name: "fk_facilities"

    Facility.find_each do |f|
      execute "INSERT INTO facility_accounts (id, facility_id, account_number, is_active, created_at, created_by) VALUES (FACILITY_ACCOUNTS_SEQ.nextVal, #{f.id}, #{f.account}, 1, SYSDATE, 1)"
    end

    remove_column :facilities, :account

    add_column :products, :facility_account_id, :integer, null: true
    execute "UPDATE products p SET p.facility_account_id = (SELECT id FROM facility_accounts fa WHERE fa.facility_id = p.facility_id)"
    change_column :products, :facility_account_id, :integer, null: false
    add_foreign_key :products, :facility_accounts, name: "fk_facility_accounts"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
