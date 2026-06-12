# frozen_string_literal: true

class InstrumentPricePolicy < PricePolicy

  include InstrumentPricePolicyCalculations
  include PricePolicies::Usage

  CHARGE_FOR = {
    usage: "usage",
    overage: "overage",
    reservation: "reservation",
  }.freeze

  validates :cancellation_cost, numericality: { allow_blank: true, greater_than_or_equal_to: 0 }
  validates :charge_for, inclusion: CHARGE_FOR.values

  after_create :ensure_reservation_window

  def reservation_window
    pgp = PriceGroupProduct.find_by(price_group_id: price_group.id, product_id: product.id)
    pgp.try(:reservation_window) || 0
  end

  def charge_full_price_on_cancellation?
    SettingsHelper.feature_on?("billing.charge_full_price_on_cancellation") && full_price_cancellation?
  end

  private

  def ensure_reservation_window
    pgp = PriceGroupProduct.find_by(price_group_id: price_group.id, product_id: product.id)

    PriceGroupProduct.create(
      price_group: price_group,
      product: product,
      reservation_window: PriceGroupProduct::DEFAULT_RESERVATION_WINDOW,
    ) unless pgp
  end

end
