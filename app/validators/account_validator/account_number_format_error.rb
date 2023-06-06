# frozen_string_literal: true

#
# Use in the validator when there are ActiveModel validation error
# on the validator. This is used to copy errors from the Validator
# to the model itself.
class  AccountValidator::AccountNumberFormatError < AccountValidator::ValidatorError

  attr_accessor :errors
  def initialize(errors)
    self.errors = errors
  end

  # TODO: test this in Northwestern
  #
  # This error is only raised in `NucsValidator#chart_string``
  def apply_to_model(model)
    errors.group_by_attribute.each do |attribute, errors|
      error = errors.first
      model.errors.add(attribute, error.type, message: error.message)
    end
  end

end
