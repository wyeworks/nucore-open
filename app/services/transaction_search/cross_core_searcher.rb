# frozen_string_literal: true

module TransactionSearch

  class CrossCoreSearcher < BaseSearcher
    def options
      ["all", "cross_core"]
    end

    def search(params)
      return order_details if params.blank?

      params = params.first

      if params == "cross_core"
        order_details.where.not(orders: { cross_core_project_id: nil })
      else
        order_details
      end
    end

    def label_method
      :humanize
    end

    def label
      I18n.t("shared.cross_core_label")
    end

    def input_type
      :select
    end

  end

end
