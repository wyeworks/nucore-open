# frozen_string_literal: true

####################################################################
# We only want to validate reservation duration changes made through
# the UI but not in specs
####################################################################
class Reservations::DurationChangeValidations

  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  attr_reader :reservation
  validate :start_time_not_changed, unless: -> { reservation.in_cart? }
  validate :duration_not_shortened, unless: -> { reservation.in_cart? }

  after_validation :copy_errors!

  def initialize(reservation)
    @reservation = reservation
  end

  def copy_errors!
    errors.each do |field, message|
      reservation.errors.add(field, message)
    end
  end

  def start_time_not_changed
    if reservation.reserve_start_at_changed? && !was_reserve_start_at_editable?(reservation)
      previous_time = reservation.reserve_start_at_was.change(sec: 0)
      updated_time = reservation.reserve_start_at.change(sec: 0)
      if previous_time != updated_time
        errors.add(:reserve_start_at, I18n.t("activerecord.errors.models.reservation.change_reserve_start_at"))
      end
    end
  end

  def duration_not_shortened
    return unless reservation.has_reserved_times?

    duration_was = TimeRange.new(reservation.reserve_start_at_was, reservation.reserve_end_at_was).duration_mins
    duration_is = TimeRange.new(reservation.reserve_start_at, reservation.reserve_end_at).duration_mins

    if duration_is < duration_was
      if reservation.started? || reservation.reserve_start_at < Time.current
        errors.add(:duration_mins, I18n.t("activerecord.errors.models.reservation.shorten_reservation_once_started"))
      elsif reservation.inside_lock_window?
        errors.add(:duration_mins, I18n.t("activerecord.errors.models.reservation.shorten_reservation_in_lock_window", lock_window: reservation.product.lock_window))
      end
    end
  end

  private

  def was_reserve_start_at_editable?(reservation)
    Reservation.find(reservation.id).reserve_start_at_editable?
  end

end
