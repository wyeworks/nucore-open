# frozen_string_literal: true

module UmassCorum

  class SubsidyAccountBuilder < AccountBuilder

    def account_params_key
      "subsidy_account"
    end

    protected

    def after_build
      account.expires_at = 5.years.from_now
    end

  end

end
