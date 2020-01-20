# frozen_string_literal: true

class AddAdminNoteToReservations < ActiveRecord::Migration[4.2]

  def change
    add_column :reservations, :admin_note, :string
  end

end
