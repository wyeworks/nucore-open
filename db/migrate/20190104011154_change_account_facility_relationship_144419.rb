# frozen_string_literal: true

class ChangeAccountFacilityRelationship144419 < ActiveRecord::Migration[5.0]
  def up
    create_table :account_facility_joins do |t|
      t.references :facility, index: { name: "idx_afj_on_facility_id" }, null: false, foreign_key: true
      t.references :account, index: { name: "idx_afj_on_account_id" }, null: false, foreign_key: true
      t.datetime :deleted_at
      t.timestamps
    end

    execute <<~SQL
      INSERT INTO account_facility_joins
      (account_id, facility_id, created_at, updated_at)
      SELECT id, facility_id, created_at, updated_at
      FROM accounts
      WHERE facility_id IS NOT NULL
    SQL
  end

  def down
    drop_table :account_facility_joins
  end

end
