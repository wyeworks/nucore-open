# frozen_string_literal: true

class OptionalRequiredNotesField < ActiveRecord::Migration[4.2]

  class Product < ActiveRecord::Base
  end

  def up
    add_column :products, :user_notes_field_mode, :string, null: false, default: "hidden"

    Product.find_each do |product|
      mode = product.note_available_to_users? ? "optional" : "hidden"
      product.update_column(:user_notes_field_mode, mode)
    end

    remove_column :products, :note_available_to_users
  end

  def down
    add_column :products, :note_available_to_users, :boolean, null: false, default: false

    Product.find_each do |product|
      product.update_column(:note_available_to_users, product.user_notes_field_mode != "hidden")
    end

    remove_column :products, :user_notes_field_mode
  end

end
