# frozen_string_literal: true

# Mailer that generates a csv report and
# sends the result.
#
# Since it receives the report instance it cannot
# be called async. See CsvReportEmailJob.
class CsvReportMailer < ApplicationMailer

  def csv_report_email(to_address, report)
    attachments[report.filename] = report.to_csv if report.has_attachment?
    mail(to: to_address, subject: report.description) do |format|
      format.text { render(plain: report.text_content) }
    end
  end

end
