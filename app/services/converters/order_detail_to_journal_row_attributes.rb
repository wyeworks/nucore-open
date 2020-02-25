# frozen_string_literal: true

module Converters

  class OrderDetailToJournalRowAttributes

    attr_accessor :journal, :order_detail, :total

    def initialize(journal, order_detail, options = {})
      @journal = journal
      @order_detail = order_detail
      @total = options[:total] || order_detail.total
    end

    def convert
      {
        account_id: order_detail.account_id,
        account: order_detail.product.account,
        amount: total,
        description: order_detail.long_description,
        order_detail: order_detail,
        journal: journal,
      }
    end

  end

end
