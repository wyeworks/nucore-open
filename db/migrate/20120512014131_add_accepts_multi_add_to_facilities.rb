# frozen_string_literal: true

class AddAcceptsMultiAddToFacilities < ActiveRecord::Migration[4.2]

  def self.up
    change_table :facilities do |t|
      t.boolean :accepts_multi_add, default: false, null: false, after: :accepts_po
    end
  end

  def self.down
    change_table :facilities do |t|
      t.remove :accepts_multi_add
    end
  end

end
