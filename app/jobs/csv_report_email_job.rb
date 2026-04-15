# frozen_string_literal: true

class CsvReportEmailJob < ApplicationJob
  def perform(report_class_name, email, **)
    report_class = report_class_name.constantize

    report = report_class.new(**)

    CsvReportMailer
      .csv_report_email(email, report)
      .deliver_now
  end

  def queue_name
    "reports"
  end
end
