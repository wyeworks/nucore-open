# frozen_string_literal: true

module TransactionSearch
  class AccountOwnerSearcher < BaseSearcher
    def options
      User.select(:id, :first_name, :last_name)
          .where(id: order_details.distinct.select("account_users.user_id").joins(account: :owner_user))
          .order(:last_name, :first_name)
    end

    def search(params)
      order_details.for_owners(params).preload(account: :owner_user)
    end

    def label_method
      [:full_name, suspended_label: false]
    end

    def label
      Account.human_attribute_name(:owner).pluralize
    end
  end
end
