# frozen_string_literal: true

module SplitAccounts
  class OrderDetailListTransformer
    attr_reader :order_details

    def initialize(order_details = [])
      @order_details = order_details
    end

    def perform(options = {})
      options ||= {} # in case it comes in as nil

      # The main advantage of using the lazy enumerator is to save memory. With it
      # we will only ever have ~1000 (plus split fake-order-details) in un-freeable
      # memory at once. It is also significantly faster to writing the first byte
      # to CSV.
      # See https://github.com/tablexi/nucore-open/pull/1341 for more details
      nested_map(order_details) do |order_detail|
        if order_detail.account.try(:splits).try(:present?)
          SplitAccounts::OrderDetailSplitter.new(
            order_detail,
            split_time_data: options[:time_data],
            reporting: options[:reporting],
          ).split
        else
          order_detail
        end
      end
    end

    private

    # Wraps a lazy enumerator with another lazy enumerator so that if the block returns
    # an Array, each value of that array gets yielded, otherwise, it'll yield the
    # result of the inner enumerator.
    #
    # Example:
    # output = nested_map(1..Float::INFINITY) do |i|
    #   if i.even?
    #     [i, i]
    #   else
    #     i
    #   end
    # end
    #
    # > output.class
    # => Enumerator::Lazy
    # > output.take(7).to_a
    # => [1, 2, 2, 3, 4, 4, 5]
    def nested_map(enumerable)
      Enumerator::Lazy.new(enumerable.to_enum) do |yielder, *values|
        results = yield(*values)
        Array(results).each do |val|
          yielder << val
        end
      end
    end
  end
end
