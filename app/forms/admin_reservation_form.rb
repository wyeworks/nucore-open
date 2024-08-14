# frozen_string_literal: true

class AdminReservationForm

  include ActiveModel::Validations
  include DateHelper

  REPEAT_OPTIONS = %w(
    daily
    weekdays_only
    weekly
    monthly
  ).freeze

  delegate :to_key, to: :reservation
  delegate :category, :reserve_start_date, :reserve_start_hour,
           :reserve_start_min, :reserve_start_meridian, :duration_mins,
           :reserve_end_date, :reserve_end_hour, :reserve_end_min,
           :reserve_end_meridian, :admin_note, :user_note, :expires?,
           :expires_mins_before, :reserve_start_at, to: :reservation
  delegate :assign_times_from_params, to: :reservation

  attr_accessor :repeats, :repeat_frequency, :repeat_end_date
  attr_reader :reservation

  validates :repeat_frequency, inclusion: { in: REPEAT_OPTIONS, allow_nil: true }
  validates :repeat_end_date, presence: true, if: :repeats?

  validate :cannot_exceed_max_end_date
  validate :repeat_end_date_after_initial_date

  def initialize(reservation)
    @reservation = reservation
  end

  def assign_attributes(attrs)
    @reservation.assign_attributes(attrs.except(:repeat_frequency, :repeat_end_date, :repeats))
    @repeats = attrs[:repeats]
    @repeat_frequency = attrs[:repeat_frequency]
    @repeat_end_date = parse_usa_date(attrs[:repeat_end_date])
  end

  def model_name
    ActiveModel::Name.new(@reservation.class)
  end

  def to_model
    self
  end

  def valid?
    [@reservation.valid?, super].each {}
    # errors does not support `merge`
    @reservation.errors.each do |error|
      errors.add(error.attribute, error.type, message: error.message)
    end
    errors.none?
  end

  def save
    if valid?
      reservations = build_recurring_reservations
      reservations.map(&:save).all?
    else
      false
    end
  end

  def build_recurring_reservations
    recurrence = Recurrence.new(reservation.reserve_start_at, reservation.reserve_end_at, until_time: repeat_end_date.try(:end_of_day))
    group_id = SecureRandom.uuid

    repeats = case repeat_frequency
              when "daily"
                recurrence.daily
              when "weekdays_only"
                recurrence.weekdays
              when "weekly"
                recurrence.weekly
              when "monthly"
                recurrence.monthly
              else
                # no repeat
                recurrence.daily.take(1)
              end

    repeats.map do |t|
      @reservation.dup.tap do |res|
        res.assign_attributes(reserve_start_at: t.start_time, reserve_end_at: t.end_time, group_id: group_id)
      end
    end
  end

  def max_end_date
    reserve_start_at + admin_hold_weeks.weeks
  end

  def cannot_exceed_max_end_date
    if repeat_end_date && repeat_end_date > max_end_date
      errors.add :repeat_end_date, :too_far_in_future, time: "#{admin_hold_weeks} weeks"
    end
  end

  def repeat_end_date_after_initial_date
    if repeat_end_date && repeat_end_date < reserve_start_at
      errors.add :repeat_end_date, :must_be_after_initial_reservation
    end
  end

  def repeats?
    repeats == "1"
  end

  def admin_hold_weeks
    Settings.admin_holds.repeat_end_date_in_weeks
  end
end
