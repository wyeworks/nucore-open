module Reports

  class Querier

    attr_reader :order_status_id, :current_facility, :date_range_field,
                :date_range_start, :date_range_end, :extra_includes

    def initialize(options = {})
      @order_status_id = options[:order_status_id]
      @current_facility = options[:current_facility]
      @date_range_field = options[:date_range_field]
      @date_range_start = options[:date_range_start]
      @date_range_end = options[:date_range_end]
      @extra_includes = options[:includes]
    end

    def perform
      OrderDetailListTransformerFactory.instance(order_details).perform
    end

    def order_details
      return [] if order_status_id.blank?

      includes = default_includes
      includes.concat(extra_includes) if extra_includes.present?

      OrderDetail.where(order_status_id: order_status_id)
                 .for_facility(current_facility)
                 .action_in_date_range(date_range_field, date_range_start, date_range_end)
                 .includes(*includes)
    end

    def default_includes
      [:account, :order, :order_status, :price_policy, :product]
    end

  end

end
