# frozen_string_literal: true

class CleanDuplicateReservations < ActiveRecord::Migration[4.2]

  class Reservation < ActiveRecord::Base
  end

  def up
    order_details_with_multiple_reservations = Reservation
                                               .where("order_detail_id is not null")
                                               .group(:order_detail_id)
                                               .having("count(*) > 1")
                                               .pluck(:order_detail_id)

    order_details_with_multiple_reservations.each do |order_detail_id|
      Reservation.where(order_detail_id: order_detail_id).last.destroy
    end
    if NUCore::Database.oracle?
      begin
        remove_index :reservations, :order_detail_id
      rescue
        # this index might not exist; unsure why
      end
    end
    add_index :reservations, :order_detail_id, unique: true, name: "res_od_uniq_fk"
  end

  def down
    remove_index :reservations, name: "res_od_uniq_fk"
    if NUCore::Database.oracle?
      add_index :reservations, :order_detail_id, name: "i_reservations_order_detail_id", tablespace: "bc_nucore"
    end
  end

end
