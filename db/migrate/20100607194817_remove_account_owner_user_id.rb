# frozen_string_literal: true

class RemoveAccountOwnerUserId < ActiveRecord::Migration[4.2]

  def self.up
    accounts = Account.all
    accounts.each do |a|
      AccountUser.create(account_id: a.id, user_id: a.owner_user_id, user_role: "Owner", created_by: a.created_by, created_at: a.created_at)
    end
    remove_column :accounts, :owner_user_id
  end

  def self.down
    add_column :accounts, :owner_user_id, :integer, null: true
    accounts = Account.all
    accounts.each do |a|
      au = a.account_users.find(:first, conditions: ["account_id = ? AND user_role = ?", a.id, "Owner"])
      execute "UPDATE accounts SET owner_user_id = #{au.user_id} WHERE id = #{au.account_id}"
      au.destroy
    end
    change_column :accounts, :owner_user_id, :integer, null: false
  end

end
