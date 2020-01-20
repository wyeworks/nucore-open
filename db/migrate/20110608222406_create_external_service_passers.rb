# frozen_string_literal: true

class CreateExternalServicePassers < ActiveRecord::Migration[4.2]

  def self.up
    create_table :external_service_passers do |t|
      t.integer :external_service_id
      t.integer :passer_id
      t.string :passer_type
      t.boolean :active, default: false
      t.timestamps
    end
  end

  def self.down
    drop_table :external_service_passers
  end

end
