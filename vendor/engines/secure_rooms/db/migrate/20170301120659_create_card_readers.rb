# frozen_string_literal: true

class CreateCardReaders < ActiveRecord::Migration[4.2]

  def change
    create_table :secure_rooms_card_readers do |t|
      t.references :product, null: false
      t.foreign_key :products

      t.string :card_reader_number
      t.string :control_device_number

      t.timestamps null: false
    end

    add_index :secure_rooms_card_readers, :product_id
  end

end
