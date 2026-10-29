# frozen_string_literal: true

module TransactionSearch
  class OrderedForSearcher < BaseSearcher
    def options
      User.select(:id, :first_name, :last_name)
          .where(id: order_details.joins(:order).distinct.select("orders.user_id"))
          .order(:last_name, :first_name)
    end

    def search(params)
      order_details.for_users(params)
    end

    def label_method
      [:full_name, suspended_label: false]
    end

    def label
      Order.human_attribute_name(:user)
    end
  end
end
