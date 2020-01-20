# frozen_string_literal: true

class AddTabletTokenToCardReaders < ActiveRecord::Migration[4.2]

  class SecureRooms::CardReader < ApplicationRecord
  end

  def change
    add_column :secure_rooms_card_readers, :tablet_token, :string
    add_index :secure_rooms_card_readers, :tablet_token, unique: true

    SecureRooms::CardReader.reset_column_information
    SecureRooms::CardReader.find_each { |cr| cr.update_column(:tablet_token, ("A".."Z").to_a.sample(12).join) }
  end

end
