# frozen_string_literal: true

module ProductNotifications
  ##
  # Notify users that a time slot is available for an instrument.
  class SlotAvailableService
    attr_reader :product, :start_time, :end_time, :exclude_user

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
      return User.none if product_notifications.blank?

      user_ids =
        product_notifications
        .joins("INNER JOIN product_notifications_users")
        .select(:user_id)

      User.where(id: user_ids).where.not(id: exclude_user&.id)
    end

    def product_notifications
      product
        .product_notifications
        .slot_available
        .where(reservation_days: slot_start_in_days..)
    end

    def slot_start_in_days
      ((start_time - Time.current) / 1.day).floor
    end
  end
end
