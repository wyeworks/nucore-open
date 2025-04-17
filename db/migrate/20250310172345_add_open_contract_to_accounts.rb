class AddOpenContractToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :open_contract, :string
  end
end
