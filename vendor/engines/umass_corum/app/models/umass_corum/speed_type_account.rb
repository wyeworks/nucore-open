# frozen_string_literal: true

module UmassCorum

  class SpeedTypeAccount < ::Account

    validates :account_number, presence: true, format: /\d{6}/, uniqueness: { case_sensitive: false }

    before_validation { self.expires_at ||= self.class.default_nil_exp_date }

    # A value is required for expires_at but the expiration date
    # for active SpeedTypes is not always known.
    # This practically means "never".
    def self.default_nil_exp_date
      100.years.from_now.end_of_day
    end

    def account_open?(_revenue_account)
      begin
        AccountValidator::ValidatorFactory.instance(account_number).account_is_open!
      rescue AccountValidator::ValidatorError
        return false
      end

      true
    end

  end

end
