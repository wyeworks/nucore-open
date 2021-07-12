# frozen_string_literal: true

class AdminReportsController < GlobalSettingsController

  def relay_data
    report = UmassCorum::AdminReports::RelayCsvReport.new

    respond_to do |format|
      format.csv { send_data report.to_csv, filename: report.filename }
    end
  end

end
