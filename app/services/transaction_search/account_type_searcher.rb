# frozen_string_literal: true

module TransactionSearch

  class AccountTypeSearcher < BaseSearcher

    def options
      Account.config.creation_enabled_types.map(&:constantize)
    end

    def search(params)
      order_details.for_account_types(params).references(:account).includes(:account)
    end

    def label_method
      :label_name
    end

    def label
      Account.human_attribute_name(:type_string)
    end

  end

end
