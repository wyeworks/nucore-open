# frozen_string_literal: true

# TODO - This is not in use by UMass, do we need to keep it?
class NufsAccount < Account

  validates_uniqueness_of :account_number, message: "already exists", case_sensitive: false
  validates_presence_of :expires_at

  validate { validate_account_number }

  after_find :load_components

  def set_expires_at
    self.expires_at = AccountValidator::ValidatorFactory.instance(account_number).latest_expiration
    # If this Validator instance has an error, suppress it. The errors
    # will be handled later.
  rescue AccountValidator::ValidatorError, AccountValidator::AccountNumberFormatError
    # Suppress the "Expiration cannot be blank" error if it's invalid for
    # some other reason
    self.expires_at ||= Time.current
  end

  def account_open?(account_num, fulfillment_time: Time.current)
    begin
      AccountValidator::ValidatorFactory.instance(account_number, account_num).account_is_open!(fulfillment_time)
    rescue AccountValidator::ValidatorError
      return false
    end

    true
  end

  #
  # Retrieves +#components+ from +AccountValidator::ValidatorFactory#instance+ and sets
  # the keys of the return as methods on this class (if necessary) and
  # then sets the value on self.
  # [_return_]
  #   The Validator from which the components were retrieved
  def load_components
    validator = AccountValidator::ValidatorFactory.instance(account_number, Settings.accounts.product_default)
    @components = validator.components

    @components.each do |k, v|
      self.class.class_eval "attr_accessor :#{k}" unless respond_to? k
      send("#{k}=", v)
    end

    validator
  rescue AccountValidator::AccountNumberFormatError => e
    raise e
  rescue => e
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    raise AccountValidator::ValidatorError.new(e)
  end

  private

  def validate_account_number
    begin
      validator = load_components
    rescue AccountValidator::AccountNumberFormatError => e
      e.apply_to_model(self)
      return
    rescue AccountValidator::ValidatorError => e
      errors.add(:account_number, e.message)
      return
    end

    begin
      validator.account_is_open!
    rescue AccountValidator::ValidatorError => e
      msg = e.message
      msg = "not found, is inactive, or is invalid" if msg.blank?
      errors.add(:account_number, msg)
    end
  end

end
