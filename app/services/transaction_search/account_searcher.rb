# frozen_string_literal: true

module TransactionSearch

  class AccountSearcher < BaseSearcher

    def options
      Account.select(:id, :account_number, :description, :type)
             .where(id: order_details.distinct.select(:account_id))
             .order(:account_number, :description)
    end

    def search(params)
      order_details.for_accounts(params).includes(:account)
    end

    def label_method
      :account_list_item
    end

  end

end
