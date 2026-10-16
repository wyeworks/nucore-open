# frozen_string_literal: true

class OrderImportJob < ApplicationJob
  def perform(order_import, report_recipient)
    return unless order_import.process_upload!

    CsvReportEmailJob.perform_later(
      "Reports::OrderImport",
      report_recipient,
      order_import:,
      **order_import.result.to_h,
    )
  end
end
