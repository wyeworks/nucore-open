# frozen_string_literal: true

class UpdateProductTableForBundles < ActiveRecord::Migration[4.2]

  def self.up
    change_column :products, :initial_order_status_id, :integer, null: true
    change_column :products, :facility_account_id,     :integer, null: true
    add_column    :products, :account_string,          :string,  null: true, limit: 5
    execute "UPDATE products SET account_string = account"
    remove_column :products, :account
    rename_column :products, :account_string, :account
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
