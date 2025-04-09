# frozen_string_literal: true

class AddTypeToReservations < ActiveRecord::Migration[4.2]

  class Reservation < ActiveRecord::Base
  end

  def up
    add_column :reservations, :type, :string
    change_column :reservations, :reserve_end_at, :datetime, null: true
    admin_reservations = Reservation.where(order_detail_id: nil)
    admin_reservations.where(reserve_end_at: nil).update_all(type: "OfflineReservation")
    admin_reservations.where.not(reserve_end_at: nil).update_all(type: "AdminReservation")
  end

  def down
    remove_column :reservations, :type
    change_column :reservations, :reserve_end_at, :datetime, null: false
  end

end
