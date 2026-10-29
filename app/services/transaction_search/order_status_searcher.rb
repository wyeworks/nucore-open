# frozen_string_literal: true

module TransactionSearch
  class OrderStatusSearcher < BaseSearcher
    def options
      # Unlike the other lookups, this query is much faster this way than using a subquery
      OrderStatus.find_by_sql(order_details.joins(:order_status)
                                           .select("distinct(order_statuses.id), order_statuses.facility_id, order_statuses.name, order_statuses.lft")
                                           .reorder("order_statuses.lft").to_sql)
    end

    def search(params)
      order_details.for_order_statuses(params).preload(:order_status)
    end

    def data_attrs(order_status)
      {}.tap do |h|
        h[:facility] = order_status.facility_id if order_status.facility_id
      end
    end
  end
end
