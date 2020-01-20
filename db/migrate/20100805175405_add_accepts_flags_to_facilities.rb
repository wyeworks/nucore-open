# frozen_string_literal: true

class AddAcceptsFlagsToFacilities < ActiveRecord::Migration[4.2]

  def self.up
    change_table :facilities do |t|
      t.boolean :accepts_cc, default: true
      t.boolean :accepts_po, default: true
    end
  end

  def self.down
    remove_column :facilities, :accepts_cc
    remove_column :facilities, :accepts_po
  end

end
