# frozen_string_literal: true

class AddShowOrderNoteToFacilities < ActiveRecord::Migration[5.2]
  def change
    change_table :facilities do |t|
      t.boolean :show_order_note, default: true , null: false
    end
  end
end
