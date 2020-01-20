# frozen_string_literal: true

class AddFacilityOrder < ActiveRecord::Migration[4.2]

  def self.up
    change_table :orders do |t|
      t.references :facility
    end
    add_foreign_key :orders, :facilities
  end

  def self.down
    remove_foreign_key :orders, :facilities
    change_table :orders do |t|
      t.remove :facility_id
    end
  end

end
