# frozen_string_literal: true

module SecureRooms
  class ScanResponsePresenter
    def self.present(verdict)
      {
        status: status_for_code(verdict.result_code),
        json: {
          tablet_identifier: verdict.card_reader.tablet_token,
          name: verdict.user&.full_name,
          response: verdict.result_code,
          reason: verdict.reason,
          accounts: SecureRooms::AccountPresenter.wrap(verdict.accounts),
        },
      }
    end

    def self.status_for_code(result_code)
      case result_code
      when :grant
        :ok
      when :deny
        :forbidden
      when :pending
        :multiple_choices
      end
    end
  end
end
