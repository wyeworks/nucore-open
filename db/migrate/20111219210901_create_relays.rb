# frozen_string_literal: true

class CreateRelays < ActiveRecord::Migration[4.2]

  def self.up
    create_table :relays do |t|
      t.integer "instrument_id"
      t.string "ip", limit: 15
      t.integer "port"
      t.string "username", limit: 50
      t.string "password", limit: 50
      t.boolean "auto_logout"
      t.string "type"
      t.timestamps
    end

    add_index :relays, :instrument_id
  end

  def self.down
    remove_index :relays, :instrument_id
    drop_table :relays
  end

end
