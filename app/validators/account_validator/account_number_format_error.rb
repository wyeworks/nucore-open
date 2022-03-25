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

  def apply_to_model(model)
    errors.messages.each do |attr, values|
      model.errors.add(attr, values.first)
    end
  end

end
