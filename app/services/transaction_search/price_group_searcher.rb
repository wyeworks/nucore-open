# frozen_string_literal: true

module TransactionSearch
  # Filter order details by price groups assigned to accounts
  class PriceGroupSearcher < BaseSearcher
    def options
      account_ids = order_details.distinct.pluck(:account_id)
      return PriceGroup.none if account_ids.empty?

      # Using joins with explicit type condition for STI
      PriceGroup.joins("INNER JOIN price_group_members ON price_group_members.price_group_id = price_groups.id")
                .where(price_group_members: {
                         account_id: account_ids,
                         type: "AccountPriceGroupMember"
                       })
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
