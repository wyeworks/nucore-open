# frozen_string_literal: true

class TestAccountValidator < AccountValidator::ValidatorDefault
  def initialize(account_number, *)
    super
    @account_number = account_number
  end

  def account_is_open!(fulfilled_at = nil)
    test_account = TestAccount.find_by(account_number: @account_number)

    return true if fulfilled_at.blank? || test_account.blank?

    return if test_account.expires_at >= fulfilled_at

    raise AccountValidator::ValidatorError, "Test account expired"
  end
end
