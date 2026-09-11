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
      show_price_breakdown: show_price_breakdown_in_csv?,
    )
  end

  private

  def show_price_breakdown_in_csv?
    SettingsHelper.feature_off?("pricing.hide_subsidy_from_customers") ||
      can?(:manage_billing, current_facility)
  end

end
