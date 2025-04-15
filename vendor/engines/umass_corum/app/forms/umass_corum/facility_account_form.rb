# frozen_string_literal: true

module UmassCorum

  class FacilityAccountForm < ::FacilityAccountForm

    before_validate_chart_string :validate_formats
    before_validate_chart_string :fetch_from_api

    private

    # Do this way as opposed to a normal validation to make sure that these validations
    # happen before the call to the API
    def validate_formats
      errors.add(:account_number, :invalid) unless /\A\d{6}\z/.match?(account_number)
      errors.add(:revenue_account, :invalid) unless /\A6\d{5}\z/.match?(revenue_account.to_s)
    end

    def fetch_from_api
      throw(:abort) if errors.any?

      raise AccountValidator::ValidatorError, api_speed_type.error_desc unless api_speed_type.active? && api_speed_type.save!
    end

    def api_speed_type
      @api_speed_type ||= UmassCorum::ApiSpeedType.find_or_initialize_from_api(account_number)
    end

  end

end
