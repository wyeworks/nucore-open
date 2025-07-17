# frozen_string_literal: true

module TransactionSearch

  ##
  # Filter order details given:
  # - :accounts: accounts ids
  #
  # It can be configured to show certain accounts as options:
  # - account_ids: [1, 2]
  class AccountSearcher < BaseSearcher
    def options
      accounts = accounts_relation.where(
        id: order_details.distinct.select(:account_id)
      )
      if account_ids
        accounts = accounts.or(Account.where(id: account_ids))
      end

      accounts
    end

    def search(params)
      order_details.for_accounts(params).includes(:account)
    end

    def label_method
      :account_list_item
    end

    def account_ids
      config[:account_ids]
    end

    def accounts_relation
      Account
        .select(:id, :account_number, :description, :type)
        .order(:account_number, :description)
    end
  end
end
