# frozen_string_literal: true

class AddDeletedAtToReservations < ActiveRecord::Migration[4.2]
  def change
    add_column :reservations, :deleted_at, :datetime
    add_index :reservations, :deleted_at
  end
end
