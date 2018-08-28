# frozen_string_literal: true

class RemoveCreditCardNumber < ActiveRecord::Migration

  def self.up
    remove_column :accounts, :credit_card_number_encrypted
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
