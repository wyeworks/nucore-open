# frozen_string_literal: true

class AllOrderDetailsValidator
  cattr_accessor :order_detail_validator_class
  attr_reader :order_details

  # Build a validator that will take a collection of order details in its constructor
  # and validate each one.
  #
  # Example:
  # validator = AllDetailsOnOrder.build(NotePresenceValidator)
  # validator.new(order_details).valid?
  #
  # This will run NotePresenceValidator.new(order_detail).valid? for each
  # element of @order_details
  def self.build(order_detail_validator_class)
    Class.new(self) do
      self.order_detail_validator_class = order_detail_validator_class
    end
  end

  # This class should only be initialized through the `.build` method
  def initialize(order_details)
    raise "Should not be initialized directly. Use the `.build` factory method instead" unless order_detail_validator_class

    @order_details = order_details
  end

  def valid?
    # Loop over everything so that all order details get `errors` applied to them
    invalid_orders = order_details.reject do |od|
      order_detail_validator_class.new(od).valid?
    end

    invalid_orders.none?
  end

  def error_message
    I18n.t(order_detail_validator_class.name.underscore, scope: "validators.all_details_on_order_validator")
  end
end
