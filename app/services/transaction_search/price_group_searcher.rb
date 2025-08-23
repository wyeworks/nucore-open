# frozen_string_literal: true

module TransactionSearch
  # Filter order details by price groups assigned to accounts
  class PriceGroupSearcher < BaseSearcher
    def options
      PriceGroup.joins(:account_price_group_members)
                .where(account_price_group_members: { account_id: order_details.distinct.select(:account_id) })
                .distinct
                .order(:name)
    end

    def search(params)
      return order_details if params.blank?

      order_details.for_price_groups(params)
    end

    def label
      PriceGroup.model_name.human
    end

    def label_method
      :name
    end
  end
end
