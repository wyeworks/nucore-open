# frozen_string_literal: true

module OrderDetail::MergeOrderHandling
  extend ActiveSupport::Concern

  included do
    before_save :move_to_original_merge_order
    after_destroy :cleanup_empty_merge_order
    after_save :cleanup_previous_merge_order
  end

  private

  def move_to_original_merge_order
    return unless order.to_be_merged? && ready_for_merge?

    # move this detail to the original order and backdate its ordered_at if
    # it was ordered in the past.
    self.order_id = order.merge_order.id
    self.ordered_at = fulfilled_at || Time.current
  end

  # Is the order 100% ready to be merged?
  def ready_for_merge?
    case product
    when Service
      valid_service_meta?
    when Instrument
      valid_reservation?
    else
      true
    end
  end

  def cleanup_previous_merge_order
    changes = saved_changes
    # check to see if #before_save switch order ids on us
    if changes.key?("order_id") && changes["order_id"][0].present?
      merge_order = Order.find changes["order_id"][0].to_i

      # clean up merge notifications
      MergeNotification.about(self).first.try(:destroy)

      # clean up detail-less merge orders
      merge_order.destroy if merge_order.to_be_merged? && merge_order.order_details.blank?
    end
  end

  # Merge orders should be cleaned up if they are without order details
  def cleanup_empty_merge_order
    order = self.order.reload
    order.destroy if order.to_be_merged? && order.order_details.empty?
  end
end
