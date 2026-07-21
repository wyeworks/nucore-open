# frozen_string_literal: true

module Reports

  module CsvExporter

    extend ActiveSupport::Concern

    include DateHelper
    include TextHelpers::Translation

    module ClassMethods

      def transformers
        @transformers ||= []
      end

    end

    def date_start
      @date_start&.in_time_zone
    end

    def date_end
      @date_end&.in_time_zone
    end

    def has_attachment?
      true
    end

    def report_data
      @report_data ||= report_data_query
    end

    def text_content
      ""
    end

    def to_csv
      @csv ||= (csv_header + csv_body).to_s
    end

    def filename
      "#{facility.name.underscore}_#{formatted_compact_date_range}.csv"
    end

    def formatted_date_range
      "#{format_usa_date(date_start)} - #{format_usa_date(date_end)}"
    end

    def formatted_compact_date_range
      [date_start, date_end].compact.map { |d| d.strftime('%Y%m%d') }.join("-")
    end

    def column_headers
      report_hash.keys.map do |key|
        text(".headers.#{key}", default: key.to_s.titleize)
      end
    end

    private

    def csv_header
      CSV.generate_line(column_headers)
    end

    def csv_body
      CSV.generate do |csv|
        # When used in delayed_job, this will make sure the query cache is on
        ActiveRecord::Base.cache do
          report_data.each { |row| csv << format_row(row) }
        end
      end
    end

    def format_row(row)
      report_hash.values.map do |callable|
        result = if callable.is_a?(Symbol)
                   row.public_send(callable)
                 else
                   callable.call(row)
        end

        if result.is_a?(DateTime)
          format_usa_datetime(result)
        else
          result
        end
      end
    rescue => e
      # Pad to full width so an errored row stays column-aligned in the CSV
      error = "*** ERROR WHEN REPORTING ON #{row.class} #{row.id}: #{e.message} ***"
      [error] + Array.new(report_hash.size - 1)
    end

    # Memoized: format_row consults it for every row, and rebuilding it means
    # re-running every registered transformer per row.
    def report_hash
      @report_hash ||= transformers.reduce(default_report_hash) do |result, class_name|
        class_name.constantize.new.transform(result)
      end
    end

    def transformers
      self.class.transformers
    end

  end

end
