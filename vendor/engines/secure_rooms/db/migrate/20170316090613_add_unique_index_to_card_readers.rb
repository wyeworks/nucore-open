# frozen_string_literal: true

class AddUniqueIndexToCardReaders < ActiveRecord::Migration[4.2]

  def change
    add_index(
      :secure_rooms_card_readers,
      [:card_reader_number, :control_device_number],
      name: "i_secure_room_reader_ids",
      unique: true,
    )
  end

end
