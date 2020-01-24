# frozen_string_literal: true

class AddAccountUsersTable < ActiveRecord::Migration[4.2]

  def self.up
    create_table :account_users do |t|
      t.references :account,    null: false
      t.integer    :user_id,    null: false
      t.string     :user_role,  null: false, limit: 50
      t.datetime   :created_at, null: false
      t.integer    :created_by, null: false
      t.datetime   :deleted_at, null: true
      t.integer    :deleted_by, null: true
    end
    execute "ALTER TABLE account_users add CONSTRAINT fk_accounts FOREIGN KEY (account_id) REFERENCES accounts (id)"
  end

  def self.down
    drop_table :account_users
  end

end
