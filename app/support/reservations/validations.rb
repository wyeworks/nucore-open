# frozen_string_literal: true

module Reservations::Validations

  extend ActiveSupport::Concern

  included do
    delegate :editing_time_data, to: :order_detail, allow_nil: true

    validates_uniqueness_of :order_detail_id, allow_nil: true
    validates :product_id, presence: true
    validates :reserve_start_at, presence: true
    validates :reserve_end_at, presence: true, if: :end_at_required?
    validate :does_not_conflict_with_other_user_reservation,
             :allowed_in_schedule_rules,
             :satisfies_minimum_length,
             :satisfies_maximum_length,
             if: ->(r) { r.reserve_start_at && r.reserve_end_at && r.reservation_changed? },
             unless: :admin?

    validates_each [:actual_start_at, :actual_end_at] do |record, attr, value|
      if value
        record.errors.add(attr.to_s, "cannot be in the future") if Time.zone.now < value
      end
    end

    validate :holiday_access
    validate :starts_before_ends
    validate :duration_is_interval
    validates :actual_duration_mins, presence: true, if: ->(r) { r.actual_start_at? && r.editing_time_data }

    # Validations when user purchasing for self
    validate :does_not_conflict_with_admin_reservation, on: [:user_purchase, :walkup_available]
    validate :in_window,
             :in_the_future,
             on: :user_purchase
    validate :starts_before_cutoff,
             on: :user_purchase,
             if: :requires_cutoff_validation?
  end

  # Validation Methods

  def starts_before_ends
    if reserve_start_at && reserve_end_at
      errors.add(:duration_mins, :zero_duration) if reserve_end_at <= reserve_start_at
    end
    if actual_start_at && actual_end_at
      errors.add(:actual_duration_mins, :zero_duration) if actual_end_at <= actual_start_at
    end
  end

  def starts_before_cutoff
    return unless starts_before_cutoff?

    errors.add(:reserve_start_at, :after_cutoff, hours: product.cutoff_hours)
  end

  def duration_is_interval
    return unless product.reserve_interval && reserve_end_at && reserve_start_at
    diff = ((reserve_end_at - reserve_start_at) / 60).to_i
    errors.add :base, :duration_not_interval, reserve_interval: product.reserve_interval unless diff % product.reserve_interval == 0
  end

  def does_not_conflict_with_other_user_reservation?
    conflicting_user_reservation.nil?
  end

  def does_not_conflict_with_other_user_reservation
    res = conflicting_user_reservation

    if res
      msg = res.order.try(:==, order) ? :conflict_in_cart : :conflict
      errors.add(:base, msg)
    end
  end

  #
  # Look for a reservation on the same instrument that conflicts in time with a
  # purchased, admin, or in-cart reservation. Should not check reservations that
  # are unpurchased in other user's carts.
  def conflicting_user_reservation(options = {})
    order_id = order_detail.try(:order_id) || 0

    conflicting_reservations =
      Reservation
      .joins_order
      .where(product_id: product.schedule.product_ids)
      .user
      .not_this_reservation(options[:exclude] || self)
      .not_canceled
      .not_ended
      .where("(orders.state = 'purchased' OR orders.state IS NULL OR orders.id = ?)", order_id)
      .overlapping(reserve_start_at, reserve_end_at)

    conflicting_reservations.first
  end

  def does_not_conflict_with_admin_reservation?
    conflicting_admin_reservation.nil?
  end

  def does_not_conflict_with_admin_reservation
    errors.add(:base, :conflict) if conflicting_admin_reservation
  end

  def conflicting_admin_reservation?
    conflicting_admin_reservation.present?
  end

  def conflicting_admin_reservation
    conflicting_reservations =
      Reservation
      .joins_order
      .where(product_id: product.schedule.product_ids)
      .not_canceled
      .not_ended
      .admin_and_offline
      .overlapping(reserve_start_at, reserve_end_at)

    conflicting_reservations.first
  end

  def satisfies_minimum_length?
    diff = reserve_end_at - reserve_start_at # in seconds
    return false unless product.min_reserve_mins.nil? || product.min_reserve_mins == 0 || diff / 60 >= product.min_reserve_mins
    true
  end

  def satisfies_minimum_length
    errors.add(:base, :too_short, length: product.min_reserve_mins) unless satisfies_minimum_length?
  end

  def satisfies_maximum_length?
    return true if product.max_reserve_mins.to_i == 0
    diff = reserve_end_at - reserve_start_at # in seconds

    # If this is updating because we're in the grace period, use the old value for checking duration
    if in_grace_period? && actual_start_at && reserve_start_at_changed? && reserve_start_at_was
      diff = reserve_end_at - reserve_start_at_was
    end

    diff <= product.max_reserve_mins.minutes
  end

  def satisfies_maximum_length
    errors.add(:base, :too_long, length: product.max_reserve_mins) unless satisfies_maximum_length?
  end

  def allowed_in_schedule_rules?
    allowed_in_schedule_rules_error.blank?
  end

  def allowed_in_schedule_rules_error
    # Everyone, including admins, are beholden to the full schedule rules
    if in_all_schedule_rules?
      :no_schedule_group unless in_allowed_schedule_rules?
    else
      :no_schedule_rule
    end
  end

  def allowed_in_schedule_rules
    error = allowed_in_schedule_rules_error
    errors.add(:base, error) if error
  end

  def in_all_schedule_rules?
    covered_by_schedule_rules?(product.schedule_rules)
  end

  def in_allowed_schedule_rules?
    # If we're saving as an administrator, they can override the user's schedule rules.
    return true if reserved_by_admin
    # Some old specs don't set an order detail, so we need to safe-navigate

    covered_by_schedule_rules?(product.available_schedule_rules(order_detail&.user_for_order))
  end

  def in_the_future?
    reserve_start_at > Time.zone.now
  end

  def in_the_future
    if reserve_start_at_changed?
      errors.add(:reserve_start_at, :in_past) unless in_the_future?
    end
  end

  # checks that the reservation is within the longest window for the groups the user is in
  def in_window?
    groups   = order_detail.price_groups
    max_days = longest_reservation_window(groups)
    diff     = reserve_start_at.to_date - Date.today
    diff <= max_days
  end

  def in_window
    errors.add(:base, :out_of_window) unless in_window?
  end

  # return the longest available reservation window for the groups
  def longest_reservation_window(groups = [])
    return default_reservation_window if groups.empty?
    product
      .price_group_products
      .where(price_group_id: groups.map(&:id))
      .pluck(:reservation_window)
      .max
  end

  def holiday_access
    return if Holiday.allow_access?(order&.created_by_user, product, reserve_start_at)

    errors.add(:reserve_start_at, :holiday_access_restricted)
  end

  private

  def starts_before_cutoff?
    return false if admin?
    reserve_start_at < product.cutoff_hours.hours.from_now
  end

  def requires_cutoff_validation?
    product.cutoff_hours && reserve_start_at && in_the_future? && reserve_start_at_changed?
  end

  def default_reservation_window
    product.price_group_products.map(&:reservation_window).min
  end

  def covered_by_schedule_rules?(schedule_rules)
    if product.daily_booking?
      schedule_rules.cover_time?(reserve_start_at)
    else
      schedule_rules.cover?(reserve_start_at, reserve_end_at)
    end
  end

end
