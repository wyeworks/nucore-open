module UmassCorum

  class SpeedTypeValidator

    attr_reader :speed_type

    def initialize(speed_type, _recharge_account = nil)
      @speed_type = speed_type
    end

    def valid_at?(_datetime)
      api_account.active?
    end

    def account_is_open!(fulfilled_at = Time.current)
      # This error should never appear in practice as the Api model should have
      # been fetched as part of account creation.
      raise ValidatorError, "Corum is unaware of this account. It should have been fetched from the API" unless api_account

      unless valid_at?(fulfilled_at)
        error = api_account.error_desc.presence || "Was not legal at the time of fulfillment"
        raise ValidatorError, error
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
