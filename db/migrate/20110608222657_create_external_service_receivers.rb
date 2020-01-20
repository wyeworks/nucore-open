# frozen_string_literal: true

class CreateExternalServiceReceivers < ActiveRecord::Migration[4.2]

  def self.up
    create_table :external_service_receivers do |t|
      t.integer :external_service_id
      t.integer :receiver_id
      t.string :receiver_type
      t.string :response_data
      t.timestamps
    end
  end

  def self.down
    drop_table :external_service_receivers
  end

end
