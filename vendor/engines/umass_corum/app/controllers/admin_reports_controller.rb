# frozen_string_literal: true

class AdminReportsController < GlobalSettingsController
  include CsvEmailAction

  def relay_data
    report = UmassCorum::AdminReports::RelayCsvReport.new
    queue_csv_report_email(report)
  end

  def user_data
    report = UmassCorum::AdminReports::UserCsvReport.new
    queue_csv_report_email(report)
  end

  def account_user_data
    report = UmassCorum::AdminReports::AccountUserCsvReport.new
    queue_csv_report_email(report)
  end

  def facility_rates_data
    report = UmassCorum::AdminReports::FacilityRatesCsvReport.new
    queue_csv_report_email(report)
  end

end
