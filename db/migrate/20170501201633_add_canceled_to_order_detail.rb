# frozen_string_literal: true

class AddCanceledToOrderDetail < ActiveRecord::Migration[4.2]

  class Reservation < ActiveRecord::Base
    belongs_to :order_detail
  end

  def up
    add_column :order_details, :canceled_at, :datetime
    add_column :order_details, :canceled_by, :integer
    add_column :order_details, :canceled_reason, :string

    Reservation.where.not(order_detail_id: nil, canceled_at: nil).includes(:order_detail).find_each do |reservation|
      next unless reservation.order_detail
      reservation.order_detail.update_columns(canceled_at: reservation.canceled_at,
                                              canceled_by: reservation.canceled_by,
                                              canceled_reason: reservation.canceled_reason)
    end
  end

  def down
    remove_column :order_details, :canceled_at, :datetime
    remove_column :order_details, :canceled_by, :integer
    remove_column :order_details, :canceled_reason, :string
  end

end
