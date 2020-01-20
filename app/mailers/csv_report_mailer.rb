# frozen_string_literal: true

class CsvReportMailer < BaseMailer

  def csv_report_email(to_address, report)
    attachments[report.filename] = report.to_csv if report.has_attachment?
    mail(to: to_address, subject: report.description) do |format|
      format.text { render(plain: report.text_content) }
    end
  end

end
