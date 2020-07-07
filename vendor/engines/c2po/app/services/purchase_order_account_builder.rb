# frozen_string_literal: true

# Contains overrides for building a `PurchaseOrderAccount` from params.
# Dynamically called via the `AccountBuilder.for()` factory.
class PurchaseOrderAccountBuilder < AccountBuilder

  # Needs to be overridable by engines
  cattr_accessor(:permitted_account_params) { [] }

  protected

  # Override strong_params for `build` account.
  def account_params_for_build
    [
      :account_number,
      :description,
      :affiliate_id,
      :affiliate_other,
      :remittance_information,
      :formatted_expires_at,
      :outside_contact_info,
      :ar_number,
    ] + permitted_account_params
  end

  # Override strong_params for `update` account.
  def account_params_for_update
    [
      :account_number,
      :description,
      :affiliate_id,
      :affiliate_other,
      :remittance_information,
      :formatted_expires_at,
      :outside_contact_info,
      :ar_number,
    ] + permitted_account_params
  end

  # Hooks into superclass's `build` method.
  def after_build
    set_expires_at
  end

  # Hooks into superclass's `update` method.
  def after_update
    set_expires_at
  end

  # Sets `expires_at` to end of the day. Assumes `expires_at` is already set
  # from params.
  def set_expires_at
    account.expires_at = account.expires_at.try(:end_of_day)
    account
  end

end
