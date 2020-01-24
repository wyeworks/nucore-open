# frozen_string_literal: true

class AddTableStatementAccounts < ActiveRecord::Migration[4.2]

  def self.up
    create_table :statement_accounts do |t|
      t.references :statement,      null: false
      t.references :account,        null: false
      t.decimal    :balance,        null: false, precision: 10, scale: 2
    end
    execute "ALTER TABLE statement_accounts add CONSTRAINT fk_st_acts_st FOREIGN KEY (statement_id) REFERENCES statements (id)"
    execute "ALTER TABLE statement_accounts add CONSTRAINT fk_st_acts_acts FOREIGN KEY (account_id) REFERENCES accounts (id)"

    remove_foreign_key :statements, name: "fk_statement_accounts"
    remove_column :statements, :account_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
