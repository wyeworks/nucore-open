# frozen_string_literal: true

class AccountValidator::ValidatorFactory

  cattr_accessor(:validator_class) do
    Settings.validator.class_name.constantize
  end

  def self.instance(*args)
    validator_class.new(*args)
  end

  #
  # Make it easy to query the validator class through the factory
  #

  def self.partition_valid_order_details(order_details)
    order_details.partition do |od|
      begin
        OrderDetailListTransformerFactory.instance([od]).perform.each do |virtual|
          instance(virtual.account.account_number, virtual.product.account).account_is_open!(virtual.fulfilled_at)
        end
        true
      rescue AccountValidator::ValidatorError
        false
      end
    end
  end

  def self.method_missing(method_sym, *arguments, &block)
    validator_class.send(method_sym, *arguments, &block)
  end

  def self.respond_to?(method_sym, include_private = false)
    return true if method_sym.in?([:validator_class, :instance])
    validator_class.respond_to? method_sym, include_private
  end

end
