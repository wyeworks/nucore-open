# frozen_string_literal: true

# Helper methods for c2po tests
#
# TODO: ideally this would live in c2po project spec
module C2poTestHelper

  def skip_if_credit_card_cannot_be_created
    skip("credit card cannot be created") unless credit_card_create_enabled?
  end

  def skip_if_credit_card_unreconcilable
    skip("credit card reconciliation disabled") unless credit_card_reconcile_enabled?
  end

  def credit_card_reconcile_enabled?
    Account.config.reconcilable_account_types.include?("CreditCardAccount")
  end

  def credit_card_create_enabled?
    Account.config.creation_enabled_types.include?("CreditCardAccount")
  end

end
