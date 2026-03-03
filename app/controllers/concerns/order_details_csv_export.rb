# frozen_string_literal: true

module OrderDetailsCsvExport

  extend ActiveSupport::Concern
  include CsvEmailAction

  def handle_csv_search
    order_detail_ids =
      @order_details.respond_to?(:pluck) ? @order_details.pluck(:id) : @order_details.map(&:id)

    queue_csv_report_email(
      Reports::AccountTransactionsReport,
      order_detail_ids:,
      date_range_field: @date_range_field,
      label_key_prefix: @label_key_prefix,
    )
  end

end
