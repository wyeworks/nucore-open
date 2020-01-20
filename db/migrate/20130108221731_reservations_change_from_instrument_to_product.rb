# frozen_string_literal: true

class ReservationsChangeFromInstrumentToProduct < ActiveRecord::Migration[4.2]

  def self.up
    # remove_foreign_key :reservations, name: "reservations_instrument_id_fk"
    rename_column :reservations, :instrument_id, :product_id
    # add_foreign_key :reservations, :products, name: "reservations_product_id_fk"
  end

  def self.down
    # remove_foreign_key :reservations, name: "reservations_product_id_fk"
    rename_column :reservations, :product_id, :instrument_id
    # add_foreign_key :reservations, :products, column: :instrument_id, name: "reservations_instrument_id_fk"
  end

end
