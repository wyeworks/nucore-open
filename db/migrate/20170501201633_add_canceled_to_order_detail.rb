class AddCanceledToOrderDetail < ActiveRecord::Migration
  def up
    add_column :order_details, :canceled_at, :datetime
    add_column :order_details, :canceled_by, :integer
    add_column :order_details, :canceled_reason, :string

    Reservation.find_each do |reservation|
      reservation.order_detail.update_attributes(canceled_at: reservation.canceled_at,
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
