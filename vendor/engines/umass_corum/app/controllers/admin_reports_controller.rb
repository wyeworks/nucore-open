# frozen_string_literal: true

class AdminReportsController < GlobalSettingsController
  include CsvEmailAction

  def relay_data
    queue_csv_report_email(UmassCorum::AdminReports::RelayCsvReport)
  end

  def user_data
    queue_csv_report_email(UmassCorum::AdminReports::UserCsvReport)
  end

  def account_user_data
    queue_csv_report_email(UmassCorum::AdminReports::AccountUserCsvReport)
  end

  def facility_rates_data
    queue_csv_report_email(UmassCorum::AdminReports::FacilityRatesCsvReport)
  end

end
