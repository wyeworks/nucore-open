# frozen_string_literal: true

module SecureRooms
  module AccessRules
    class AccountSelectionRule < BaseRule
      def evaluate
        accounts = user.accounts_for_product(card_reader.secure_room)
        selected_account = accounts.find { |account| account.id == requested_account_id }

        if accounts.blank?
          deny!(:no_accounts)
        elsif selected_account.present?
          grant!(:selected_account, selected_account:, accounts:)
        elsif accounts.present? && selected_account.blank?
          pending!(:selection_needed, accounts:)
        end
      end

      private

      def requested_account_id
        params[:requested_account_id].to_i
      end
    end
  end
end
