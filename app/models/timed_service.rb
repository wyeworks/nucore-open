# frozen_string_literal: true

class TimedService < Product

  module Pricing

    STANDARD = "Schedule Rule"
    DURATION = "Duration"

  end

  PRICING_MODES = [Pricing::STANDARD, Pricing::DURATION].freeze

  has_many :timed_service_price_policies, foreign_key: :product_id

  validates_presence_of :initial_order_status_id
  validates :pricing_mode, presence: true, inclusion: { in: PRICING_MODES }

  def quantity_as_time?
    true
  end

  def order_quantity_as_time?
    true
  end

  def time_unit
    "mins"
  end

  def duration_pricing_mode?
    pricing_mode == Pricing::DURATION
  end

end
