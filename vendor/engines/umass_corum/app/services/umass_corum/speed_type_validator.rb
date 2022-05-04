# frozen_string_literal: true

module UmassCorum

  class SpeedTypeValidator

    attr_reader :speed_type

    def initialize(speed_type, _recharge_account = nil)
      @speed_type = speed_type
    end

    def account_suspended_at?(fulfilled_at)
      suspended_account = UmassCorum::SpeedTypeAccount.where(account_number: speed_type)
                                                       .where.not(suspended_at: nil)
                                                       .first
      suspended_account.present? && fulfilled_at > suspended_account.suspended_at
    end

    def valid_at?(fulfilled_date, start_date)
      if api_account.active?
        start_date <= fulfilled_date
      elsif api_account.date_removed.present?
        start_date <= fulfilled_date && fulfilled_date <= api_account.date_removed
      else
        # This should never happen - api_account should be active OR have date_removed set
        if defined?(Rollbar)
          Rollbar.warning("Expired SpeedType with no expiration date", account_number: api_account.speed_type)
        end
        false
      end
    end

    def account_is_open!(fulfilled_at = Time.current)
      # This error should never appear in practice as the Api model should have
      # been fetched as part of account creation.
      raise AccountValidator::ValidatorError, "Corum is unaware of this account. It should have been fetched from the API" unless api_account

      raise AccountValidator::ValidatorError, "This account is suspended" if account_suspended_at?(fulfilled_at)

      active_date = api_account.date_added_admin_override || api_account.date_added

      unless valid_at?(fulfilled_at, active_date)
        error = api_account.error_desc.presence || "Was not legal at the time of fulfillment"
        raise AccountValidator::ValidatorError, error
      end

      true
    end

    # Not used by UMass. Other schools split their chartstrings into segments like
    # `org` or `project`.
    def components
      {}
    end

    def api_account
      return @api_account if defined?(@api_account)

      @api_account = UmassCorum::ApiSpeedType.find_by(speed_type: speed_type)
    end

    # [_return_]
    #   the latest expiration date for a payment source
    def latest_expiration
      UmassCorum::SpeedTypeAccount.default_nil_exp_date
    end

  end

end
