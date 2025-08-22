# frozen_string_literal: true

module TransactionSearch
  # Only enabled when billing_table_price_groups feature flag is on
  class PriceGroupSearcher < BaseSearcher
    def options
      return [] unless SettingsHelper.feature_on?(:billing_table_price_groups)

      PriceGroup.joins(:account_price_group_members)
                .where(account_price_group_members: { account_id: order_details.distinct.select(:account_id) })
                .distinct
                .order(:name)
    end

    def search(params)
      return order_details if params.blank?
      return order_details unless SettingsHelper.feature_on?(:billing_table_price_groups)

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
