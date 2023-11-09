# frozen_string_literal: true

class DurationRate < ApplicationRecord

  belongs_to :price_policy
  belongs_to :rate_start, required: true

  validate :rate_or_subsidy
  validates :rate, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
  validates :subsidy, numericality: { greater_than: 0, allow_blank: true }

  # TODO: Validate:
  # - Rate is <= base rate (if Price group is the “base” group or external).
  # - Subsidy is <= base rate (if Price group is internal but not the “base”).
  # For this it looks like we'll need to link Rate Start to Price Policy, instead of Instrument.
  # In this context we only have a Price Group (which can have N Price policies) and an Instrument (which can have N Price policies).
  # We need a Price Policy as that's where we store the usage_rate.
  # Also, makes sense that Steps for an Instrument can change in time but we may want to keep the historic data.


  private
  def rate_or_subsidy
    if rate.blank? && subsidy.blank?
      errors.add(:base, "Either Rate or Adjustment must be provided")
    end
  end
end
