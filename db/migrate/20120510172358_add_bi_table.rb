# frozen_string_literal: true

class AddBiTable < ActiveRecord::Migration[4.2]

  def self.up
    if NUCore::Database.oracle?
      create_table :bi_netids do |t|
        t.string :netid, null: false
        t.references :facility, null: false
        t.foreign_key :facilities
      end

      add_index :bi_netids, :netid
      add_index :bi_netids, :facility_id
    else
      puts <<-WARN
        >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        You're not running Oracle, so it's unlikely you need the table this migration creates(bi_netids).
        The table was not created. If you really want to run this migration on Oracle you need to rollback
        to the previous migration version and remove the condition that caused this message.
        <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
      WARN
    end
  end

  def self.down
    remove_index :bi_netids, :netid
    remove_index :bi_netids, :facility_id
    drop_table :bi_netids
  end

end
