# frozen_string_literal: true

class OrderDetailObserver < ActiveRecord::Observer

  def after_destroy(order_detail)
    # merge orders should be cleaned up if they are without order details
    order = order_detail.order.reload
    order.destroy if order.to_be_merged? && order.order_details.empty?
  end

  def before_save(order_detail)
    order = order_detail.order
    product = order_detail.product

    # Is the order 100% ready to be merged?
    if order.to_be_merged? && (product.is_a?(Item) ||
                              (product.is_a?(Service) && order_detail.valid_service_meta?) ||
                              (product.is_a?(Instrument) && order_detail.valid_reservation?))

      # move this detail to the original order and backdate its ordered_at if
      # it was ordered in the past.
      order_detail.order_id = order.merge_order.id
      order_detail.ordered_at = order_detail.fulfilled_at || Time.current
    end
  end

  def after_save(order_detail)
    changes = order_detail.changes
    # check to see if #before_save switch order ids on us
    if changes.key?("order_id") && changes["order_id"][0].present?
      merge_order = Order.find changes["order_id"][0].to_i

      # clean up merge notifications
      MergeNotification.about(order_detail).first.try(:destroy)

      # clean up detail-less merge orders
      merge_order.destroy if merge_order.to_be_merged? && merge_order.order_details.blank?
    end
  end

end
