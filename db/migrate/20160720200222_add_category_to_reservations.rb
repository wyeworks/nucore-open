# frozen_string_literal: true

class AddCategoryToReservations < ActiveRecord::Migration[4.2]

  def change
    add_column :reservations, :category, :string, null: true
  end

end
