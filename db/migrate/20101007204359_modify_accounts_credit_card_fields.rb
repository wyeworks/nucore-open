# frozen_string_literal: true

class ModifyAccountsCreditCardFields < ActiveRecord::Migration[4.2]

  def self.up
    add_column    :accounts, :credit_card_number_encrypted, :string, limit: 200, null: true
    remove_column :accounts, :credit_card_number
    remove_column :accounts, :display_account_number
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
