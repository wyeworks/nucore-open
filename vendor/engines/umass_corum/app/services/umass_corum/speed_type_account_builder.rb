# frozen_string_literal: true

module UmassCorum

  class SpeedTypeAccountBuilder < AccountBuilder
    include ::DateHelper

    def account_params_key
      "speed_type_account"
    end

    protected

    def after_update
      api_account = account.api_speed_type
      return unless api_account

      date_string = params[:speed_type_account][:api_speed_type_attributes][:date_added_admin_override]
      api_account.date_added_admin_override = parse_usa_date(date_string) if date_string.present?
      api_account.save!
    end

    def after_build
      # account_number will be blank on `new`, and we don't want the form to start with errors
      return if account.account_number.blank? || account.invalid?

      api_account = ApiSpeedType.find_or_initialize_from_api(account.account_number)

      if api_account.active?
        api_account.save!
      else
        account.errors.add(:base, api_account.error_desc)
      end
    end

  end

end
