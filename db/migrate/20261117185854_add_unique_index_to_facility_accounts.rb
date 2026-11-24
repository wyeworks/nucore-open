# frozen_string_literal: true

class AddUniqueIndexToFacilityAccounts < ActiveRecord::Migration[8.0]
  def change
    add_index :facility_accounts,
              [:facility_id, :revenue_account, :account_number],
              unique: true,
              name: "index_facility_accounts_on_facility_revenue_account_number"
  end
end
