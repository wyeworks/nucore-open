# frozen_string_literal: true

class FacilityAccountForm < SimpleDelegator

  include ActiveModel::Validations
  include ActiveModel::Callbacks

  define_model_callbacks :validate_chart_string

  validate :validate_chart_string

  def self.model_name
    ActiveModel::Name.new(FacilityAccount)
  end

  def self.i18n_scope
    :activerecord
  end

  def to_model
    self
  end

  def valid?
    # Don't bother validating ourself if the object is already invalid
    if facility_account.valid? && super
      true
    else
      facility_account.errors.each do |error|
        errors.add(error.attribute, error.type, message: error.message)
      end
      false
    end
  end

  def save
    valid? && facility_account.save(validate: false) # skip validations because we've already done them
  end

  def update_form_attributes(*args)
    assign_attributes(*args)
    save
  end

  private

  def facility_account
    __getobj__
  end

  # Hook into the callbacks by declaring `before_validate_chart_string :my_method_to_run`
  def validate_chart_string
    run_callbacks :validate_chart_string do
      AccountValidator::ValidatorFactory.instance(account_number, revenue_account).account_is_open!
    end
  rescue AccountValidator::AccountNumberFormatError => e
    e.apply_to_model(self)
  rescue AccountValidator::ValidatorError => e
    errors.add(:base, e.message)
  end

end
