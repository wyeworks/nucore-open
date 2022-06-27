# frozen_string_literal: true

# Contains overrides for building a `NufsAccount` from params.
# Dynamically called via the `AccountBuilder.for()` factory.
class NufsAccountBuilder < AccountBuilder

  protected

  # Override strong_params for `build` account.
  def account_params_for_build
    super + [{ account_number_parts: NufsAccount.account_number_field_names }]
  end

  # Hooks into superclass's `build` method.
  def after_build
    load_account_components

    account.set_expires_at
    # This is kind of a weird message to be adding here (the message is about)
    # not finding the fund, dept, activity, etc, but leaving here to preserve
    # existing behavior
    account.errors.add(:base, :missing_expires_at) unless account.expires_at
  end

  private

  def load_account_components
    # if we're loading the builder in a #new action, this won't be populated yet
    return unless account.account_number

    # This will populate virtual fields like fund, dept
    account.load_components
  rescue AccountValidator::AccountNumberFormatError
    # do nothing
  rescue AccountValidator::ValidatorError => e
    account.errors.add(:base, e.message)
  end

end
