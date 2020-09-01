# frozen_string_literal: true

class ChangeAccountFacilityRelationship144419 < ActiveRecord::Migration[5.0]
  def up
    create_table :account_facility_joins do |t|
      t.references :facility, index: true, null: false, foreign_key: true
      t.references :account, index: true, null: false, foreign_key: true
      t.datetime :deleted_at
      t.timestamps
    end

    if Nucore::Database.oracle?
      execute <<~SQL
        INSERT INTO account_facility_joins (id, account_id, facility_id, created_at, updated_at)
        SELECT ACCOUNT_FACILITY_JOINS_SEQ.NEXTVAL, account_id, facility_id, created_at, updated_at
        FROM (
          SELECT id account_id, facility_id, created_at, updated_at
          FROM accounts
          WHERE facility_id IS NOT NULL
        )
      SQL
    else
      execute <<~SQL
        INSERT INTO account_facility_joins (account_id, facility_id, created_at, updated_at)
        SELECT id, facility_id, created_at, updated_at
        FROM accounts
        WHERE facility_id IS NOT NULL
      SQL
    end
  end

  def down
    drop_table :account_facility_joins
  end

end
