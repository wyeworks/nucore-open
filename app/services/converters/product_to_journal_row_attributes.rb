# frozen_string_literal: true

module Converters

  class ProductToJournalRowAttributes

    attr_accessor :journal, :product, :total

    def initialize(journal, product, total)
      @journal = journal
      @product = product
      @total = total
    end

    def convert
      {
        account: product.facility_account.revenue_account_for_journal,
        amount: total * -1,
        description: product.to_s,
        journal_id: journal.try(:id),
      }
    end

  end

end
