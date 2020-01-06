
# frozen_string_literal: true

class OrderPurchaseValidator

  # The AllOrderDetailsValidator will validate each individual OrderDetail
  # within the order using the NotePresenceValidator.
  cattr_accessor(:additional_validations) do
    [
      AllOrderDetailsValidator.build(NotePresenceValidator),
      OrderResearchSafetyCertificationValidator,
    ]
  end

  attr_reader :errors

  def initialize(order_details)
    @order_details = Array(order_details)
    @errors = []
  end

  def valid?
    additional_validations.all? do |validator_class|
      validator = validator_class.new(@order_details)
      if validator.valid?
        true
      else
        @errors << validator.error_message
        false
      end
    end
  end

  def invalid?
    !valid?
  end

end
