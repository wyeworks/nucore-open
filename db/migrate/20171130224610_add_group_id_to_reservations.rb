# frozen_string_literal: true

class AddGroupIdToReservations < ActiveRecord::Migration[4.2]
  def change
    add_column :reservations, :group_id, :string

    add_index :reservations, :group_id
  end
end
