# frozen_string_literal: true

# Contains overrides for building a `CreditCardAccount` from params.
# Dynamically called via the `AccountBuilder.for()` factory.
class CreditCardAccountBuilder < AccountBuilder

  protected

  # Override strong_params for `build` account.
  def account_params_for_build
    [
      :account_number,
      :description,
      :affiliate_id,
      :affiliate_other,
      :remittance_information,
      :expiration_month,
      :expiration_year,
      :name_on_card,
    ]
  end

  # Override strong_params for `update` account.
  def account_params_for_update
    [
      :description,
      :affiliate_id,
      :affiliate_other,
      :remittance_information,
      :expiration_month,
      :expiration_year,
    ]
  end

  # Hooks into superclass's `build` method.
  def after_build
    set_expires_at
  end

  # Hooks into superclass's `update` method.
  def after_update
    set_expires_at
  end

  # Sets `expires_at` based off of the credit card expiration year and month.
  def set_expires_at
    if account.expiration_year.present? && account.expiration_month.present?
      account.expires_at = Date.civil(account.expiration_year.to_i, account.expiration_month.to_i).end_of_month.end_of_day
    end
  end

end
