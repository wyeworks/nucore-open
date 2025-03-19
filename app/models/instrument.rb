# frozen_string_literal: true

class Instrument < Product

  module Pricing

    SCHEDULE_RULE = "Schedule Rule"
    SCHEDULE_DAILY = "Schedule Rule (Daily Booking only)"
    DURATION = "Duration"

  end

  include Products::RelaySupport
  include Products::ScheduleRuleSupport
  include Products::SchedulingSupport
  include EmailListAttribute

  RESERVE_INTERVALS = [1, 5, 10, 15, 30, 60].freeze
  RESERVE_INTERVAL_DAILY = 1

  PRICING_MODES = [Pricing::SCHEDULE_RULE, Pricing::DURATION].tap do |pricing_modes|
    if SettingsHelper.feature_on?(:show_daily_rate_option)
      pricing_modes.insert(1, Pricing::SCHEDULE_DAILY)
    end
  end.freeze

  with_options foreign_key: "product_id" do
    has_many :admin_reservations
    has_many :instrument_price_policies
    has_many :offline_reservations
  end

  email_list_attribute :cancellation_email_recipients
  email_list_attribute :issue_report_recipients

  # Validations
  # --------

  validates :initial_order_status_id, presence: true
  validates :reserve_interval, presence: true, inclusion: { in: RESERVE_INTERVALS, allow_blank: true }, if: -> { !daily_booking? }
  validates :min_reserve_mins,
            :max_reserve_mins,
            :auto_cancel_mins,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :cutoff_hours, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :minimum_reservation_is_multiple_of_interval,
           :maximum_reservation_is_multiple_of_interval,
           :max_reservation_not_less_than_min

  validates :pricing_mode, presence: true, inclusion: { in: PRICING_MODES }

  # Callbacks
  # --------

  # Triggered by Product
  # after_create :create_default_price_group_products

  before_create :clean_up_reservation_rules

  # Scopes
  # --------

  def self.reservation_only
    joins("LEFT OUTER JOIN relays ON relays.instrument_id = products.id")
      .where("relays.instrument_id IS NULL")
  end
  # Instance methods
  # -------

  def time_data_field
    :reservation
  end

  # calculate the last possible reservation date based on all current price policies associated with this instrument
  def last_reserve_date
    (Time.zone.now.to_date + max_reservation_window.days).to_date
  end

  def max_reservation_window
    days = price_group_products.collect(&:reservation_window).max.to_i
  end

  def requires_merge?
    true
  end

  def create_default_price_group_products
    PriceGroup.globals.find_each do |price_group|
      price_group_products.create!(
        price_group:,
        reservation_window: PriceGroupProduct::DEFAULT_RESERVATION_WINDOW
      )
    end
  end

  def reservation_only?
    control_mechanism == Relay::CONTROL_MECHANISMS[:manual]
  end

  def quantity_as_time?
    true
  end

  def blackout_reservations(date)
    ScheduleRule.unavailable(schedule_rules).select { |rule| rule.on_day?(date) }.map do |rule|
      Reservation.new(
        product: self,
        reserve_start_at: date.change(hour: rule.start_hour, min: rule.start_min),
        reserve_end_at: date.change(hour: rule.end_hour, min: rule.end_min),
        blackout: true,
      )
    end
  end

  def duration_pricing_mode?
    pricing_mode == Pricing::DURATION
  end

  def daily_booking?
    pricing_mode == Pricing::SCHEDULE_DAILY
  end

  def can_apply_discounts?
    !(duration_pricing_mode? || daily_booking?)
  end

  private

  def minimum_reservation_is_multiple_of_interval
    validate_multiple_of_reserve_interval :min_reserve_mins
  end

  def maximum_reservation_is_multiple_of_interval
    validate_multiple_of_reserve_interval :max_reserve_mins
  end

  def validate_multiple_of_reserve_interval(attribute)
    field_value = send(attribute).to_i
    # other validations will handle the errors if these are false
    return unless reserve_interval.to_i > 0 && field_value > 0

    if field_value % reserve_interval != 0
      errors.add attribute, :not_interval, reserve_interval:
    end
  end

  def max_reservation_not_less_than_min
    if max_reserve_mins && min_reserve_mins && max_reserve_mins < min_reserve_mins
      errors.add :max_reserve_mins, :max_less_than_min
    end
  end

  def clean_up_reservation_rules
    if daily_booking?
      self.min_reserve_mins = nil
      self.max_reserve_mins = nil
      self.reserve_interval = RESERVE_INTERVAL_DAILY
    else
      self.min_reserve_days = nil
      self.max_reserve_days = nil
    end
  end

end
