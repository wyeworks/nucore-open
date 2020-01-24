# frozen_string_literal: true

class AlterOrderDetailsDropDisputeResolvedCredit < ActiveRecord::Migration[4.2]

  def self.up
    details = OrderDetail.where("dispute_resolved_credit IS NOT NULL")

    details.each do |detail|
      detail.actual_cost = detail_actual_cost - detail.dispute_resolved_credit
      detail.save!
    end

    remove_column :order_details, :dispute_resolved_credit
  end

  def self.down
    add_column :order_details, :dispute_resolved_credit, :decimal, precision: 10, scale: 2
  end

end
