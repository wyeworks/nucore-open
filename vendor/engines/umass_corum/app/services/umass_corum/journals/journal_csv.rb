module UmassCorum

  module Journals

    class JournalCsv

      include ::Reports::CsvExporter

      def initialize(journal)
        @journal = journal
      end

      def report_data_query
        @journal.journal_rows.where.not(amount: 0)
      end

      def render
        to_csv
      end

      private

      def report_hash
        {
          business_unit: :business_unit,
          account: :account,
          speed_type: :speed_type,
          fund: :fund,
          dept_id: :dept_id,
          program: :program,
          class: :clazz,
          project: :project,
          amount: :amount,
          description: :description,
          name_reference: :name_reference,
          trans_date: ->(journal_row) { format_usa_date(journal_row.trans_date) },
          doc_ref: :doc_ref,
          ref_2: :ref_2,
          trans_ref: ->(journal_row) { journal_row.journal.facility.abbreviation[0, 11] },
        }
      end

      def column_headers
        report_hash.keys.map { |header| header.to_s.titleize }
      end

    end

  end

end
