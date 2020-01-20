# frozen_string_literal: true

class UpdateEvents < ActiveRecord::Migration[4.2]

  def change
    change_column :secure_rooms_events, :card_reader_id, :integer, null: false
    change_column :secure_rooms_events, :user_id, :integer, null: false
    add_column :secure_rooms_events, :account_id, :integer
    add_index :secure_rooms_events, :account_id
    add_foreign_key :secure_rooms_events, :accounts
  end

end
