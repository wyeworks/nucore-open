# frozen_string_literal: true

class AlterProductsRemoveRelays < ActiveRecord::Migration[4.2]

  def self.up
    remove_column(:products, :relay_ip)
    remove_column(:products, :relay_port)
    remove_column(:products, :relay_username)
    remove_column(:products, :relay_password)
    remove_column(:products, :relay_type)
    remove_column(:products, :auto_logout)
  end

  def self.down
    change_table :products do |t|
      t.column "relay_ip", :string, limit: 15
      t.column "relay_port", :integer
      t.column "relay_username", :string, limit: 50
      t.column "relay_password", :string, limit: 50
      t.column "auto_logout", :boolean
      t.column "relay_type", :string, limit: 50
    end
  end

end
