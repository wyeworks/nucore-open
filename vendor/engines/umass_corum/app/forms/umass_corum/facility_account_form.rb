# frozen_string_literal: true

module UmassCorum

  class FacilityAccountForm < ::FacilityAccountForm

    before_validate_chart_string :validate_formats
    before_validate_chart_string :fetch_from_api

    private

    # Do this way as opposed to a normal validation to make sure that these validations
    # happen before the call to the API
    def validate_formats
      errors.add(:account_number, :invalid) unless account_number =~ /\A\d{6}\z/
      errors.add(:revenue_account, :invalid) unless revenue_account.to_s =~ /\A6\d{5}\z/
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
