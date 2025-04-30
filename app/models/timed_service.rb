# frozen_string_literal: true

class TimedService < Product

  has_many :timed_service_price_policies, foreign_key: :product_id

  validates_presence_of :initial_order_status_id

  def quantity_as_time?
    true
  end

  def order_quantity_as_time?
    true
  end

  def time_unit
    "mins"
  end

end
