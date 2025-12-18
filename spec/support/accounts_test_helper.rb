# frozen_string_literal: true

module AccountsTestHelper

  def skip_if_account_cannot_be_created(account_type)
    return if Account.config.creation_enabled_types.include?(
      to_account_class(account_type))

    skip("#{account_type} cannot be created")
  end

  def skip_if_account_unreconcilable(account_type)
    return if Account.config.reconcilable_account_types.include?(
      to_account_class(account_type))

    skip("#{account_type} cannot be reconciled")
  end

  def skip_if_custom_reconciliation_viewhooks_present
    return unless ViewHook.find("facility_accounts_reconciliation.index", "reconciliation_heading").any?

    skip("Purchase Order reconciliation uses different flow when viewhooks are present")
  end

  def to_account_class(account_type)
    account_type = account_type.to_s.camelize

    return account_type if account_type.end_with? "Account"

    "#{account_type}Account"
  end

end
