module Journals

  class DefaultJournalCsv

    include Reports::CsvExporter

    def initialize(journal)
      @journal = journal
    end

    def report_data_query
      @journal.journal_rows
    end

    def render
      to_csv
    end

    private

    def default_report_hash
      {
        facility: ->(row) { row.order_detail&.facility },
        order_number: ->(row) { row.order_detail },
        transaction_date: ->(row) { format_usa_date(row.order_detail&.fulfilled_at) },
        account_number: ->(row) { row.order_detail&.account&.account_number },
        account: :account,
        amount: :amount,
        description: :description,
      }
    end

    def column_headers
      report_hash.keys.map { |header| header.to_s.titleize }
    end

  end

end
