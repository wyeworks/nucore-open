# frozen_string_literal: true

module TransactionSearch
  class FacilitySearcher < BaseSearcher
    def options
      Facility.find_by_sql(order_details.joins(order: :facility)
                                        .select("distinct(facilities.id), facilities.name, facilities.abbreviation")
                                        .reorder("facilities.name").to_sql)
    end

    def search(params)
      order_details.for_facilities(params).includes(order: :facility)
    end
  end
end
