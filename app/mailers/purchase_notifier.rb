# frozen_string_literal: true

class PurchaseNotifier < ApplicationMailer

  include DateHelper
  add_template_helper ApplicationHelper
  add_template_helper OrdersHelper
  add_template_helper ViewHookHelper

  default from: Settings.email.from, content_type: "multipart/alternative"

  # Notifies the specified facility staff member if an order is placed including a product
  def product_order_notification(order_detail, recipient)
    @order = order_detail.order
    @order_detail = OrderDetailPresenter.new(order_detail)
    attach_reservation_ical(order_detail.reservation) if order_detail.reservation.present?
    send_nucore_mail recipient, text("views.purchase_notifier.product_order_notification.subject", product: order_detail.product)
  end

  # Notifies the specified facility staff member if any order is placed within a facility
  def order_notification(order, recipient)
    @order = order
    attach_all_icals_from_order(@order)
    send_nucore_mail recipient, text("views.purchase_notifier.order_notification.subject"), "order_receipt"
  end

  # Custom order forms send out a confirmation email when filled out by a
  # customer. Customer gets one along with PI/Admin/Lab Manager.
  def order_receipt(args)
    @user = args[:user]
    @order = args[:order]
    @greeting = text("views.purchase_notifier.order_receipt.intro")
    attach_all_icals_from_order(@order)
    send_nucore_mail args[:user].email, text("views.purchase_notifier.order_receipt.subject")
  end

  private

  def attach_all_icals_from_order(order)
    order.order_details.map(&:reservation).compact.each do |reservation|
      attach_reservation_ical(reservation)
    end
  end

  def attach_reservation_ical(reservation)
    calendar = ReservationCalendar.new(reservation)
    attachments[calendar.filename] = {
      mime_type: "text/calendar", content: [calendar.to_ical]
    }
  end

  def send_nucore_mail(to, subject, template_name = nil)
    mail(subject: subject, to: to, template_name: template_name)
  end

end
