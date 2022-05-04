class AddAccountNumberIndexToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_index :accounts, :account_number
  end
end
