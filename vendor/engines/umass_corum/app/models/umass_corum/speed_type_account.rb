# frozen_string_literal: true

module UmassCorum

  class SpeedTypeAccount < ::Account
    has_one :api_speed_type,
            foreign_key: :speed_type,
            primary_key: :account_number,
            required: false,
            inverse_of: :speed_type_account

    accepts_nested_attributes_for :api_speed_type

    validates :account_number, presence: true, format: /\d{6}/, uniqueness: { case_sensitive: false }

    before_validation { self.expires_at ||= self.class.default_nil_exp_date }

    # A value is required for expires_at but the expiration date
    # for active SpeedTypes is not always known.
    # This practically means "never".
    def self.default_nil_exp_date
      100.years.from_now.end_of_day
    end

    def account_open?(_revenue_account = nil, fulfillment_time: Time.current)
      begin
        AccountValidator::ValidatorFactory.instance(account_number).account_is_open!(fulfillment_time)
      rescue AccountValidator::ValidatorError
        return false
      end

      true
    end

  end

end
