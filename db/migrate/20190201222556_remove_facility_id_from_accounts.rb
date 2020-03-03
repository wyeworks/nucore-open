# frozen_string_literal: true

class RemoveFacilityIdFromAccounts < ActiveRecord::Migration[5.0]
  def up
    remove_foreign_key :accounts, :facilities
    remove_column :accounts, :facility_id
  end

  def down
    add_reference :accounts,
                  :facility,
                  after: "remittance_information",
                  foreign_key: { name: "fk_account_facility_id" },
                  index: { name: "fk_account_facility_id" }

    # If there happen to be more than one join, then :shrug:, only one will get set.
    execute <<~SQL
      UPDATE accounts
      SET accounts.facility_id = (
        SELECT facility_id
        FROM account_facility_joins
        WHERE accounts.id = account_facility_joins.account_id
        ORDER BY account_facility_joins.created_at
        LIMIT 1
      )
    SQL
  end
end
