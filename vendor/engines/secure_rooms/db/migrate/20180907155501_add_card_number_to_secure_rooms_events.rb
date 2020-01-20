# frozen_string_literal: true

class AddCardNumberToSecureRoomsEvents < ActiveRecord::Migration[4.2]

  def up
    add_column :secure_rooms_events, :card_number, :string
    update <<~SQL
      UPDATE secure_rooms_events
      SET card_number =
        (SELECT card_number
         FROM users
         WHERE users.id = secure_rooms_events.user_id)
    SQL
    change_column :secure_rooms_events, :card_number, :string, null: false
  end

  def down
    remove_column :secure_rooms_events, :card_number
  end

end
