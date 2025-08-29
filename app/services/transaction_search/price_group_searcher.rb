# frozen_string_literal: true

module TransactionSearch
  class PriceGroupSearcher < BaseSearcher
    def options
      PriceGroup.all
    end

    def search(price_group_ids)
      return order_details if price_group_ids.empty?

      order_details
        .joins(:price_policy)
        .where(price_policy: { price_group: price_group_ids })
    end

    def label
      PriceGroup.model_name.human
    end

    def label_method
      :name
    end
  end
end
