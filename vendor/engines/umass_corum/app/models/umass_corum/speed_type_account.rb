# frozen_string_literal: true

module UmassCorum

  class SpeedTypeAccount < ::Account

    validates :account_number, presence: true, format: /\d{6}/, uniqueness: true

    # This practically means "never"
    before_validation { self.expires_at ||= 100.years.from_now.end_of_day }

    def account_open?(_revenue_account)
      begin
        ValidatorFactory.instance(account_number).account_is_open!
      rescue ValidatorError
        return false
      end

      true
    end

  end

end
