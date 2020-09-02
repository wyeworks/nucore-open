# frozen_string_literal: true

class OrderDetailDisputeMailerPreview < ActionMailer::Preview

  def dispute_resolved
    order_detail = Nucore::Database.random(OrderDetail.where.not(dispute_resolved_at: nil))
    OrderDetailDisputeMailer.dispute_resolved(order_detail: order_detail, user: order_detail.user)
  end

end
