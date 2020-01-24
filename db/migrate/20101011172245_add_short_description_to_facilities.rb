# frozen_string_literal: true

class AddShortDescriptionToFacilities < ActiveRecord::Migration[4.2]

  def self.up
    add_column :facilities, :short_description, :text, null: false
  end

  def self.down
    remove_column :facilities, :short_description
  end

end
