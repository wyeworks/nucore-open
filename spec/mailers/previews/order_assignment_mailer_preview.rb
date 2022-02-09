# frozen_string_literal: true

class OrderAssignmentMailerPreview < ActionMailer::Preview

  def order_assignment
    OrderAssignmentMailer.with(order_details: order_detail).notify_assigned_user
  end

  private

  def order_detail
    OrderDetail.where.not(assigned_user_id: nil).last.presence ||
      OrderDetail.last.tap { |od| od.assigned_user_id = User.last }
  end

end
