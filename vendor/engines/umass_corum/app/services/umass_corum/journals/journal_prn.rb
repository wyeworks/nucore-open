module UmassCorum

  module Journals

    class JournalPrn

      include DateHelper

      def initialize(journal)
        @journal = journal
      end

      def render(batch: false)
        writer = UmassCorum::JournalWriter.new(
          headers: headers
        )

        rows_to_export.each do |journal_row|
          writer << hash_for(journal_row)
        end

        batch ? writer.to_a : writer.to_s
      end

      private

      def rows_to_export
        @journal.journal_rows.where.not(amount: 0)
      end

      def headers
        {
          trans_code: "$$$",
          um_batch_id: rows_to_export.first&.ref_2,
          batch_date: @journal.journal_date,
          batch_desc: @journal.facility.name,
          batch_trans_count: rows_to_export.size,
          batch_trans_amount: total_journal_amount,
          batch_originator: @journal.created_by_user.username.upcase,
          batch_business_unit: "UMAMH",
        }
      end

      def hash_for(journal_row)
        {
          speedtype: journal_row.speed_type,
          account: journal_row.account,
          trans_ref: journal_row.journal.facility.abbreviation,
          trans_date: journal_row.trans_date,
          trans_desc: journal_row.description,
          amount: journal_row.amount.abs,
          credit_debit: journal_row.amount.positive? ? "D" : "C",
          trans_2nd_ref: journal_row.ref_2,
          trans_id: journal_row.trans_id,
          campus_business_unit: journal_row.business_unit,
          trans_3rd_ref: journal_row.trans_3rd_ref,
          name: journal_row.name_reference,
          doc_reference: journal_row.doc_ref,
          fund_code: journal_row.fund,
          department_id: journal_row.dept_id,
          program_code: journal_row.program,
          project_id: journal_row.project,
        }
      end

      # The total they want is the total of both debits and credits, and since they
      # match up, the total should always be double the amount we would probably expect.
      def total_journal_amount
        rows_to_export.map(&:amount).map(&:abs).sum
      end
    end

  end

end
