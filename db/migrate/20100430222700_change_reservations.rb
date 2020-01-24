# frozen_string_literal: true

class ChangeReservations < ActiveRecord::Migration[4.2]

  def self.up
    change_table :reservations do |t|
      t.references  :order_detail
      t.references  :instrument, null: false
      t.datetime    :reserve_start_at, null: false
      t.datetime    :reserve_end_at,   null: false
      t.datetime    :actual_start_at
      t.datetime    :actual_end_at
    end

    add_foreign_key :reservations, :order_details
    add_foreign_key :reservations, :products, column: :instrument_id, name: "reservations_instrument_id_fk"
  end

  def self.down
    change_table :reservations do |t|
      t.remove   :order_detail_id
      t.remove   :instrument_id
      t.remove   :reserve_start_at
      t.remove   :reserve_end_at
      t.remove   :actual_start_at
      t.remove   :actual_end_at
    end
    remove_foreign_key :reservations, :order_details
    remove_foreign_key :reservations, :products, name: "reservations_instrument_id_fk"
  end

end
