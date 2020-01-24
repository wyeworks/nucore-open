# frozen_string_literal: true

class CreateExternalServices < ActiveRecord::Migration[4.2]

  def self.up
    create_table :external_services do |t|
      t.string :type
      t.string :location
      t.timestamps
    end
  end

  def self.down
    drop_table :external_services
  end

end
