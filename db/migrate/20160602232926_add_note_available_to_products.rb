# frozen_string_literal: true

class AddNoteAvailableToProducts < ActiveRecord::Migration[4.2]

  def change
    add_column :products, :note_available_to_users, :boolean, default: false, null: false
  end

end
