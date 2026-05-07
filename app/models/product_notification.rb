# frozen_string_literal: true

class ProductNotification < ApplicationRecord
  belongs_to :product

  DEFAULT_RESERVATION_DAYS = 15

  enum :notification_type, { slot_available: "slot_available" }
  enum :recipient_source, { access_list: "access_list", reservations: "reservations" }, prefix: :recipients

  store :data, accessors: %i[recipients reservation_days], coder: JSON

  validates_uniqueness_of :notification_type, scope: :product_id
  validates_presence_of :notification_type, :recipient_source

  validates(
    :reservation_days,
    numericality: { greater_than: 0, less_than_or_equal_to: 30 },
    if: :recipients_reservations?,
  )

  def reservation_days
    return if (value = super).nil?

    value.to_i
  end
end
