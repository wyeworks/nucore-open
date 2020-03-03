module UmassCorum

  module Journals

    class JournalPrn

      include DateHelper

      def initialize(journal)
        @journal = journal
      end

      def render
        writer = UmassCorum::JournalWriter.new(
          headers: headers
        )

        @journal.journal_rows.find_each do |journal_row|
          writer << hash_for(journal_row)
        end

        writer.to_s
      end

      private

      def headers
        {
          trans_code: "$$$",
          um_batch_id: @journal.journal_rows.first.ref_2,
          batch_date: @journal.journal_date,
          batch_desc: @journal.facility.name,
          batch_trans_count: @journal.journal_rows.size,
          batch_trans_amount: @journal.amount,
          batch_originator: @journal.created_by_user.username.upcase,
          batch_business_unit: "UMAMH",
        }
      end

      def hash_for(journal_row)
        {
          speedtype: journal_row.speed_type,
          account: journal_row.account,
          trans_ref: journal_row.trans_ref,
          trans_date: journal_row.trans_date,
          trans_desc: journal_row.description,
          amount: journal_row.amount.abs,
          credit_debit: journal_row.amount.positive? ? "D" : "C",
          trans_2nd_ref: journal_row.ref_2,
          campus_business_unit: journal_row.business_unit,
          name: journal_row.name_reference,
          doc_reference: journal_row.doc_ref,
          fund_code: journal_row.fund,
          department_id: journal_row.dept_id,
          program_code: journal_row.program,
          project_id: journal_row.project,
        }
      end
    end

  end

end
