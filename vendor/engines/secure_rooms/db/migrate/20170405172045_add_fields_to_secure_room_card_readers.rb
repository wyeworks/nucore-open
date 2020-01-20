# frozen_string_literal: true

class AddFieldsToSecureRoomCardReaders < ActiveRecord::Migration[4.2]

  def change
    add_column :secure_rooms_card_readers, :direction_in, :boolean, null: false, default: true
  end

end
