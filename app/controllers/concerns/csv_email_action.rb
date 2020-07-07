# frozen_string_literal: true

module CsvEmailAction

  extend ActiveSupport::Concern

  # Example usage:
  # yield_email_and_respond_for_report do |email|
  #   CsvReportMailer.delay.csv_report_email(email, report)
  # end
  def yield_email_and_respond_for_report
    csv_send_to_email = params[:email] || current_user.email

    yield csv_send_to_email

    if request.xhr?
      render plain: I18n.t("controllers.reports.mail_queued", email: csv_send_to_email)
    else
      flash[:notice] = I18n.t("controllers.reports.mail_queued", email: csv_send_to_email)
      redirect_back(fallback_location: url_for)
    end
  end

  def queue_csv_report_email(report)
    yield_email_and_respond_for_report do |email|
      # TODO: in order to use ActiveJob's `deliver_later`, the report needs to be
      # specifically serializable, which many of our reports are not.
      CsvReportMailer.delay.csv_report_email(email, report)
    end
  end

end
