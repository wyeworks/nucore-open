# frozen_string_literal: true

module Projects

  class CrossCoreFacilitySearcher < TransactionSearch::BaseSearcher
    include TextHelpers::Translation

    def self.key
      :cross_core_facilties
    end

    def options
      ["other", "current", "all"]
    end

    def search(params)
      return order_details if params.blank?

      selected_value = params.first

      if selected_value == "other"
        order_details.where.not(orders: { facility_id: @current_facility_id })
      elsif selected_value == "current"
        order_details.where(orders: { facility_id: @current_facility_id })
      else
        order_details
      end
    end

    def label_method
      :humanize
    end

    def label
      text("projects.projects.cross_core_orders.filter_label")
    end

    def input_type
      :select
    end

    # Translation scope cannot be inferred, so we need to specify it.
    # Returns empty string because label includes the complete path.
    def translation_scope
      ""
    end
  end

end
