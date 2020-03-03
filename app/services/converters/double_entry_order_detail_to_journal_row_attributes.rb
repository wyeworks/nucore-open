module Converters

  class DoubleEntryOrderDetailToJournalRowAttributes

    attr_accessor :journal, :order_detail, :total

    def initialize(journal, order_detail, options = {})
      @journal = journal
      @order_detail = order_detail
      @total = options[:total] || order_detail.total
    end

    def convert
      [
        expense_attributes.reverse_merge(default_expense_attributes),
        revenue_attributes.reverse_merge(default_revenue_attributes),
      ]
    end

    # Override in a subclass returning a Hash
    def expense_attributes
      {}
    end

    # Override in a subclass returning a Hash
    def revenue_attributes
      {}
    end

    private

    def default_expense_attributes
      {
        # A journal has_many order_details through the journal rows. Only the expenses
        # should have an order detail so we don't double count the order details.
        order_detail: order_detail,
        account_id: order_detail.account_id,
        journal: journal,
        # Note: this is the expense account, not the Account association
        account: order_detail.product.account,
        amount: total,
        description: order_detail.long_description,
      }
    end

    def default_revenue_attributes
      {
        amount: total * -1,
        account: order_detail.product.facility_account.revenue_account,
        journal: journal,
        description: order_detail.product.to_s,
      }
    end

  end

end
