# frozen_string_literal: true

module OrderDetailsHelper

  def can_edit_fulfilled_at?(order_detail, user)
    return true if order_detail.complete? && user.administrator?

    order_detail.fulfilled_at.blank? || order_detail.fulfilled_at_changed?
  end

end
