# frozen_string_literal: true

module Reports
  class Querier
    # This seems to be ideal for NU/Oracle, but we can consider tweaking for MySQL
    BATCH_SIZE = 500

    attr_reader :order_status_id, :current_facility, :date_range_field,
                :date_range_start, :date_range_end, :batch_size, :options

    def initialize(options = {})
      @options = options
      @order_status_id = options[:order_status_id]
      @current_facility = options[:current_facility]
      @date_range_field = options[:date_range_field]
      @date_range_start = options[:date_range_start]
      @date_range_end = options[:date_range_end]
      @transformer_options = options[:transformer_options]
      @batch_size = options[:batch_size] || BATCH_SIZE
    end

    def perform
      OrderDetailListTransformerFactory.instance(order_details).perform(@transformer_options)
    end

    def order_details
      return OrderDetail.none if order_status_id.blank?

      OrderDetail.where(order_status_id:)
                 .for_facility(current_facility)
                 .action_in_date_range(date_range_field, date_range_start, date_range_end)
                 .joins(:order, :account)
                 .includes(*includes)
                 .preload(*preloads)
                 .merge(Order.purchased)
                 .find_each(batch_size:)
    end

    private

    def includes
      [:order, :price_policy] + Array(options[:includes])
    end

    def preloads
      [:product, :order_status, :account] + Array(options[:preloads])
    end
  end
end
