# frozen_string_literal: true

class AddInstrumentsRelayUsernameAndPassword < ActiveRecord::Migration[4.2]

  def self.up
    add_column :products, :relay_username, :string, null: true, limit: 50
    add_column :products, :relay_password, :string, null: true, limit: 50
  end

  def self.down
    remove_column :products, :relay_username
    remove_column :products, :relay_password
  end

end
