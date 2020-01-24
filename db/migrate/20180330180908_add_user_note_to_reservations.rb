# frozen_string_literal: true

class AddUserNoteToReservations < ActiveRecord::Migration[4.2]
  def change
    add_column :reservations, :user_note, :string
  end
end
