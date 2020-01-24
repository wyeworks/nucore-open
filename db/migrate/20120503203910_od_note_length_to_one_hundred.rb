# frozen_string_literal: true

class OdNoteLengthToOneHundred < ActiveRecord::Migration[4.2]

  def self.up
    change_column :order_details, :note, :string, limit: 100
  end

  def self.down
    change_column :order_details, :note, :string, limit: 25
  end

end
