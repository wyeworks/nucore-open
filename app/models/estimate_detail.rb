# frozen_string_literal: true

class EstimateDetail < ApplicationRecord
  belongs_to :estimate, inverse_of: :estimate_details
  belongs_to :product
  belongs_to :price_policy

  before_save :assign_price_policy_and_cost

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  delegate :user, to: :estimate

  def price_groups
    return [PriceGroup.nonbillable] if product.nonbillable_mode?

    user.price_groups.uniq
  end

  private

  def assign_price_policy_and_cost
    pp_and_cost = product.cheapest_price_policy(self, Time.current)

    return unless pp_and_cost[:price_policy]

    self.price_policy = pp_and_cost[:price_policy]
    self.cost = pp_and_cost[:cost]
  end
end
