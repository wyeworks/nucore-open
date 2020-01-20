# frozen_string_literal: true

class AddReconciliationDateToOrderDetail < ActiveRecord::Migration[4.2]

  def up
    add_column :order_details, :reconciled_at, :datetime

    OrderDetail.where(state: "reconciled").where("journal_id IS NOT NULL").find_each do |od|
      od.update_attribute(:reconciled_at, od.journal.journal_date)
    end
  end

  def down
    remove_column :order_details, :reconciled_at
  end

end
