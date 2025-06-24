# frozen_string_literal: true

module TransactionSearch

  class DateRangeSearcher < BaseSearcher
    include DateHelper
    extend TextHelpers::Translation

    FIELDS = %w(ordered_at fulfilled_at journal_or_statement_date reconciled_at).freeze

    attr_reader :date_range_field

    class << self
      def options(only: FIELDS)
        FIELDS
          .map { |field| [text(field), field] }
          .select { |_label, value| value.in?(only) }
      end

      def translation_scope
        "admin.transaction_search.date_range_fields"
      end
    end

    def options
      self.class.options
    end

    def multipart?
      true
    end

    def search(params)
      params ||= {}
      start_date = to_date(params[:start])
      end_date = to_date(params[:end])
      @date_range_field = extract_date_range_field(params)

      order_details
        .action_in_date_range(@date_range_field, start_date, end_date)
        .ordered_by_action_date(@date_range_field)
    end

    def to_date(param_value)
      parse_usa_date(param_value.to_s.tr("-", "/"))
    end

    def extract_date_range_field(params)
      field = params.try(:[], :field)
      FIELDS.include?(field.to_s) ? field.to_s : "fulfilled_at"
    end

  end

end
