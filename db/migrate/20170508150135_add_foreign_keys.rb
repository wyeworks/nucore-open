# frozen_string_literal: true

class AddForeignKeys < ActiveRecord::Migration[4.2]

  def change
    add_index :notifications, [:subject_id, :subject_type]
    add_index :order_statuses, :parent_id
    add_index(:orders, :merge_with_order_id) unless index_exists?(:orders, :merge_with_order_id)
    add_index(:price_group_members, :account_id) unless index_exists?(:price_group_members, :account_id)
    add_index :products, :initial_order_status_id

    add_foreign_key :account_users, :users
    add_foreign_key :journal_rows, :accounts
    add_foreign_key :journal_rows, :journals
    add_foreign_key :journal_rows, :order_details
    add_foreign_key :order_details, :users, column: :assigned_user_id
    add_foreign_key :order_details, :journals
    add_foreign_key :order_details, :order_statuses
    add_foreign_key :order_details, :statements
    add_foreign_key :orders, :order_imports
    add_foreign_key :orders, :orders, column: :merge_with_order_id
    add_foreign_key :orders, :users
    add_foreign_key :price_group_members, :accounts
    add_foreign_key :price_group_members, :users
    add_foreign_key :product_users, :users
    add_foreign_key :statement_rows, :order_details
    add_foreign_key :statement_rows, :statements
    add_foreign_key :statements, :accounts
    add_foreign_key :user_roles, :facilities
    add_foreign_key :user_roles, :users
  end

end
