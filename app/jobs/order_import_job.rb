# frozen_string_literal: true

class OrderImportJob < ApplicationJob
  def perform(order_import, report_recipient)
    order_import.process_upload!
    report = Reports::OrderImport.new(order_import)

    CsvReportMailer
      .csv_report_email(report_recipient, report)
      .deliver_now
  end
end
