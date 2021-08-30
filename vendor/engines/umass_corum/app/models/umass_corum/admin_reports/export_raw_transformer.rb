# frozen_string_literal: true

require "hash_helper"

module UmassCorum

  module AdminReports

    class ExportRawTransformer

      include HashHelper

      def transform(original_hash)
        insert_into_hash_after(original_hash, :reference_id, als_number: method(:als_number))
      end

      private

      def als_number(order_detail)
        return unless order_detail.journal.present?
        order_detail.journal.journal_rows.first&.ref_2
      end

    end

  end

end
