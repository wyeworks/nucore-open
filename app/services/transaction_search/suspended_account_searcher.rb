# frozen_string_literal: true

module TransactionSearch
  class SuspendedAccountSearcher < BaseSearcher
    def search(params)
      if params.present? && to_bool(params.first)
        order_details.where(account: Account.not_suspended)
      else
        order_details
      end
    end

    def input_type
      :boolean
    end

    def label
      I18n.t("admin.transaction_search.suspended_accounts")
    end

    def to_bool(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
