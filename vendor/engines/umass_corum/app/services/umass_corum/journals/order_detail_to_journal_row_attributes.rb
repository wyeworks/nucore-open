# frozen_string_literal: true

module UmassCorum

  module Journals

    class OrderDetailToJournalRowAttributes < ::Converters::DoubleEntryOrderDetailToJournalRowAttributes

      private

      def expense_attributes
        common_attributes(speed_type: order_detail.account.account_number)
      end

      def revenue_attributes
        expense_speed_type = speed_type_cache[order_detail.account.account_number]
        common_attributes(speed_type: order_detail.product.facility_account.account_number).merge(
          # dept_desc is "IALS M2M" for recharges, but we want to use the expense account's department for this field
          doc_ref: extract_doc_ref(expense_speed_type.dept_desc),
          trans_3rd_ref: expense_speed_type.speed_type, # the expense account speedtype is more useful for reporting, so we want it to show up in Summit
        )
      end

      def common_attributes(speed_type:)
        api_speed_type = speed_type_cache[speed_type]
        {
          speed_type: speed_type,
          fund: api_speed_type.fund_code,
          dept_id: api_speed_type.dept_id,
          program: api_speed_type.program_code,
          clazz: api_speed_type.clazz,
          project: api_speed_type.project_id, # This will be blank in the API for recharges
          trans_ref: nil, # Intentionally blank
          description: order_detail.account.owner_user.last_first_name(suspended_label: false).first(20),
          name_reference: order_detail.order_number,
          trans_date: order_detail.fulfilled_at,
          trans_id: journal.facility&.abbreviation, # safe navigation only used in testing
          doc_ref: extract_doc_ref(api_speed_type.dept_desc),
          ref_2: journal_als,
          trans_3rd_ref: nil, # Intentionally blank
        }
      end

      # Returns the journal batch ID. E.g. ALS034. It rolls over after ALS999
      def journal_als
        als_number = journal.als_number.presence || journal.id
        "#{als_prefix}#{format('%03d', als_number % 1000)}"
      end

      def als_prefix
        custom_journal_prexifes[journal.facility&.url_name] || "ALS" # safe navigation only used in testing
      end

      def custom_journal_prexifes
        {
          "data-corps" => "DCR",
          "gel-permeation-chromatography" => "GPC",
          "proposal-support-services" => "PSS"
        }
      end

      # This field is something like "Biology-Maresca,Thomas". The first part is
      # the department
      def extract_doc_ref(desc)
        desc.split("-").first.first(9)
      end

      def speed_type_cache
        @speed_type_cache ||= Hash.new { |hash, value| hash[value] = UmassCorum::ApiSpeedType.find_by!(speed_type: value) }
      end

    end

  end

end
