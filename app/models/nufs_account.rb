class NufsAccount < Account
  validates_uniqueness_of :account_number, message: "already exists"
  validates_presence_of :expires_at

  validate { validate_account_number }

  after_find :load_components

  def set_expires_at!
    self.expires_at = ValidatorFactory.instance(account_number).latest_expiration
  end

  def account_open?(account_num)
    begin
      ValidatorFactory.instance(account_number, account_num).account_is_open!
    rescue ValidatorError
      return false
    end

    return true
  end

  def can_reconcile?(order_detail)
    order_detail.journal.try(:successful?) ||
      OrderDetail.need_journal.exists?(order_detail.id)
  end

  private

  #
  # Retrieves +#components+ from +ValidatorFactory#instance+ and sets
  # the keys of the return as methods on this class (if necessary) and
  # then sets the value on self.
  # [_return_]
  #   The Validator from which the components were retrieved
  def load_components
    validator = ValidatorFactory.instance(account_number, NUCore::COMMON_ACCOUNT)
    @components = validator.components

    @components.each do |k,v|
      self.class.class_eval "attr_accessor :#{k}" unless respond_to? k
      send("#{k}=", v)
    end

    validator
  rescue AccountNumberFormatError => e
    raise e
  rescue => e
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    raise ValidatorError.new(e)
  end

  def validate_account_number
    begin
      validator = load_components
    rescue AccountNumberFormatError => e
      e.apply_to_model(self)
      return
    rescue ValidatorError => e
      self.errors.add(:account_number, e.message)
      return
    end

    begin
      validator.account_is_open!
    rescue ValidatorError => e
      msg=e.message
      msg="not found, is inactive, or is invalid" if msg.blank?
      self.errors.add(:account_number, msg)
    end
  end
end
