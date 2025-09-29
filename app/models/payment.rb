# frozen_string_literal: true

class Payment < ApplicationRecord

  belongs_to :account, inverse_of: :payments
  belongs_to :statement, inverse_of: :payments, optional: true
  belongs_to :paid_by, class_name: "User", optional: true

  # Add additional sources in an engine with Payment.valid_sources << :new_source
  def self.valid_sources
    @@valid_sources ||= [:check]
  end

  validates :source,
            presence: true,
            inclusion: {
              in: ->(*) { valid_sources.map(&:to_s) },
              message: "%{value} is not a valid payment source type",
            }

  validates :account, presence: true

  validates :amount,
            presence: true,
            numericality: { other_than: 0, message: "may not be 0" }

  validates :processing_fee, presence: true, numericality: true, allow_nil: false

end
