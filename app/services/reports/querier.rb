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
      @extra_preloads = options[:preloads]
      @extra_joins = options[:joins]
      @transformer_options = options[:transformer_options]
    end

    def perform
      OrderDetailListTransformerFactory.instance(order_details).perform(@transformer_options)
    end

    def order_details
      return [] if order_status_id.blank?

      includes = default_includes
      includes.concat(extra_includes) if extra_includes.present?

      OrderDetail.where(order_status_id: order_status_id)
                 .for_facility(current_facility)
                 .action_in_date_range(date_range_field, date_range_start, date_range_end)
                 .joins(*([:order, :account] + Array(@extra_joins)))
                 .includes(*includes)
                 .preload(*(default_preloads + Array(@extra_preloads)))
                 .merge(Order.purchased)
    end

    def default_includes
      [:order, :price_policy]
    end

    def default_preloads
      [:product, :order_status, :account]
    end

  end

end
