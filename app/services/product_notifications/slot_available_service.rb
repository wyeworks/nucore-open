# frozen_string_literal: true

module ProductNotifications
  ##
  # Notify users that a time slot is available for an
  # instrument.
  class SlotAvailableService
    attr_reader :product, :start_time, :end_time, :exclude_user

    delegate :product_notification, to: :product

    def self.from_reservation(reservation)
      new(
        reservation.order_detail.product,
        reservation.reserve_start_at,
        reservation.reserve_end_at,
        exclude_user: reservation.order_detail.user,
      )
    end

    def initialize(product, start_time, end_time, exclude_user: nil)
      @product = product
      @start_time = start_time
      @end_time = end_time
      @exclude_user = exclude_user
    end

    def notify!
      recipients.find_each do |user|
        ProductNotificationMailer.slot_available(
          product, user, start_time, end_time
        ).deliver_later
      end
    end

    private

    def recipients
      all_recipient_users.where.not(id: exclude_user&.id)
    end

    def all_recipient_users
      return User.none unless product_notification.try(:slot_available?)

      if product_notification.recipients_reservations?
        upcoming_reservation_users
      elsif product_notification.recipients_access_list?
        User.where(id: product.product_users.select(:user_id))
      end
    end

    def upcoming_reservation_users
      window_days =
        product_notification.reservation_days ||
        ProductNotification::DEFAULT_RESERVATION_DAYS

      # upcoming reservations after empty time slot
      reservations =
        product
        .reservations
        .upcoming(end_time)
        .where(reserve_start_at: ...window_days.days.from_now)

      User.where(id: reservations.select(:user_id))
    end
  end
end
