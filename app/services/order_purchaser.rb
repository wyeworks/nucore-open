# frozen_string_literal: true

class OrderPurchaser

  attr_reader :acting_as, :order, :order_in_past, :params, :user
  attr_accessor :backdate_to

  alias acting_as? acting_as
  alias order_in_past? order_in_past

  delegate :order_notification_recipient, to: :order

  def initialize(acting_as:, order:, order_in_past:, params:, user:)
    @acting_as = acting_as
    @order = order
    @order_in_past = order_in_past
    @params = params
    @user = user
    @success = false
    @errors = []
  end

  def purchase!
    order_detail_updater.update!
    if order_detail_updater.quantities_changed?
      @errors << I18n.t("controllers.orders.purchase.quantities_changed")
      return
    end

    order.order_details_ordered_at = backdate_to if backdate_to

    validate_order!
    return unless do_additional_validations
    purchase_order!

    order_in_the_past! if order_in_past?

    send_purchase_notifications

    @success = true
  rescue NUCore::OrderDetailUpdateException => e
    @errors = order.errors.full_messages
  end

  def success?
    @success
  end

  def errors
    @errors.compact.uniq
  end

  private

  def order_detail_updater
    @order_detail_updater ||= OrderDetailUpdater.new(order, order_update_params)
  end

  def order_in_the_past!
    unless can_backdate_order_details?
      raise NUCore::PurchaseException.new(I18n.t("controllers.orders.purchase.future_dating_error"))
    end

    # update order detail statuses if you've changed it while acting as
    if acting_as? && order_status.present?
      backdate_order_details!(user, order_status)
    end
    complete_past_reservations!
  end

  def can_backdate_order_details?
    order.initial_ordered_at <= Time.zone.now
  end

  def backdate_order_details!(update_by, order_status)
    order.order_details.each do |od|
      next if od.reservation # reservations should always have order_status dictated by their dates

      if order_status.root == OrderStatus.complete
        od.backdate_to_complete!(od.ordered_at)
      else
        od.update_order_status!(update_by, order_status, admin: true)
      end
    end
  end

  def complete_past_reservations!
    order.order_details.select { |od| od.reservation && od.reservation.reserve_end_at < Time.zone.now }.each do |od|
      od.backdate_to_complete! od.reservation.reserve_end_at
    end
  end

  def order_status
    OrderStatus.find(params[:order_status_id]) if params[:order_status_id]
  end

  def order_update_params
    @order_update_params ||= OrderDetailUpdateParamHashExtractor.new(params).to_h
  end

  def quantities
    order.order_details.order("order_details.id").pluck(:quantity)
  end

  def send_purchase_notifications
    should_send_receipt = !acting_as? || params[:send_notification] == "1"
    should_send_order_notification = order_notification_recipient.present? && !acting_as?

    if should_send_receipt
      PurchaseNotifier.order_receipt(user: order.user, order: order).deliver_later
    end

    if should_send_order_notification
      PurchaseNotifier.order_notification(order, order_notification_recipient).deliver_later
    end

    order.order_details.each do |order_detail|
      next unless order_detail.product.order_notification_recipient?
      PurchaseNotifier.product_order_notification(order_detail, order_detail.product.order_notification_recipient).deliver_later
    end
  end

  def validate_order!
    # Empty because validate_order! and purchase! don't give useful error messages
    raise NUCore::PurchaseException.new("") unless order.validate_order!
  end

  def purchase_order!
    # Empty because validate_order! and purchase! don't give useful error messages
    raise NUCore::PurchaseException.new("") unless order.purchase!
  end

  def do_additional_validations
    validator = OrderPurchaseValidator.new(@order.order_details)
    if validator.valid?
      true
    else
      @errors = validator.errors
      false
    end
  end

end
