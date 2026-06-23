# frozen_string_literal: true

module ProductNotifications
  ##
  # Notify users that a time slot is available for an instrument.
  class SlotAvailableService
    attr_reader :product, :start_time, :end_time, :exclude_user

    def self.from_reservation(reservation)
      new(
        reservation.product,
        reservation.reserve_start_at,
        reservation.reserve_end_at,
        exclude_user: reservation.order_detail&.user,
      )
    end

    def initialize(product, start_time, end_time, exclude_user: nil)
      @product = product
      @start_time = start_time
      @end_time = end_time
      @exclude_user = exclude_user
    end

    def notify_later
      SlotAvailableJob.perform_later(product, start_time, end_time, exclude_user:)
    end

    def notify!
      return unless should_notfy?

      product_notifications.find_each do |product_notification|
        users =
          product_notification
          .users
          .active
          .where.not(id: exclude_user&.id)

        users.find_each do |user|
          ProductNotificationMailer.slot_available(
            product, user,
            start_time, end_time,
            subject: product_notification.email_subject.presence,
          ).deliver_later
        end
      end
    end

    private

    def should_notfy?
      [
        SettingsHelper.feature_on?("notifications.facility_product_notifications"),
        start_time&.future?,
        product_schedulable?,
      ].all?
    end

    def product_schedulable?
      product.schedule_rules.cover?(start_time, end_time)
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
