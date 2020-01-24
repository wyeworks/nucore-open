# frozen_string_literal: true

class AddStatementFields < ActiveRecord::Migration[4.2]

  def self.up
    add_column :statements, :account_id,  :integer,  null: false
    add_column :statements, :facility_id, :integer,  null: false
    add_column :statements, :created_by,  :integer,  null: false
    add_column :statements, :created_at,  :datetime, null: false
    execute "ALTER TABLE statements add CONSTRAINT fk_statement_accounts FOREIGN KEY (account_id) REFERENCES accounts (id)"
    execute "ALTER TABLE statements add CONSTRAINT fk_statement_facilities FOREIGN KEY (facility_id) REFERENCES facilities (id)"
  end

  def self.down
    execute "ALTER TABLE statements DROP CONSTRAINT fk_statement_accounts"
    execute "ALTER TABLE statements DROP CONSTRAINT fk_statement_facilities"
    remove_column :statements, :account_id
    remove_column :statements, :facility_id
    remove_column :statements, :created_by
    remove_column :statements, :created_at
  end

end
