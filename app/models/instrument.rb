# frozen_string_literal: true

class Instrument < Product

  include Products::RelaySupport
  include Products::ScheduleRuleSupport
  include Products::SchedulingSupport
  include EmailListAttribute

  RESERVE_INTERVALS = [1, 5, 10, 15, 30, 60].freeze

  # Associations
  # -------

  has_many :instrument_price_policies, foreign_key: "product_id"
  has_many :admin_reservations, foreign_key: "product_id"
  has_many :offline_reservations, foreign_key: "product_id"
  has_one :alert, dependent: :destroy, class_name: "InstrumentAlert"

  email_list_attribute :cancellation_email_recipients

  # Validations
  # --------

  validates :initial_order_status_id, presence: true
  validates :reserve_interval, inclusion: { in: RESERVE_INTERVALS }
  validates :min_reserve_mins,
            :max_reserve_mins,
            :auto_cancel_mins,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :cutoff_hours, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :minimum_reservation_is_multiple_of_interval,
           :maximum_reservation_is_multiple_of_interval,
           :max_reservation_not_less_than_min

  # Callbacks
  # --------

  after_create :set_default_pricing

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

  def mergeable?
    true
  end

  def set_default_pricing
    PriceGroup.globals.find_each do |pg|
      PriceGroupProduct.create!(product: self, price_group: pg, reservation_window: PriceGroupProduct::DEFAULT_RESERVATION_WINDOW)
    end
  end

  def reservation_only?
    control_mechanism == Relay::CONTROL_MECHANISMS[:manual]
  end

  def quantity_as_time?
    true
  end

  def has_alert?
    alert.present?
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
      errors.add attribute, :not_interval, reserve_interval: reserve_interval
    end
  end

  def max_reservation_not_less_than_min
    if max_reserve_mins && min_reserve_mins && max_reserve_mins < min_reserve_mins
      errors.add :max_reserve_mins, :max_less_than_min
    end
  end

end
