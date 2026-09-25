# frozen_string_literal: true

module CsvEmailAction

  extend ActiveSupport::Concern

  # Example usage:
  # yield_email_and_respond_for_report do |email|
  #   CsvReportEmailJob.perform_later(report_class.to_s, email, **report_args)
  # end
  def yield_email_and_respond_for_report(fallback_location: url_for)
    csv_send_to_email = params[:email] || current_user.email

    yield csv_send_to_email

    if request.xhr?
      render plain: I18n.t("controllers.reports.mail_queued", email: csv_send_to_email)
    else
      flash[:notice] = I18n.t("controllers.reports.mail_queued", email: csv_send_to_email)
      redirect_back_or_to(fallback_location)
    end
  end

  def queue_csv_report_email(report_class, fallback_location: url_for, **report_args)
    yield_email_and_respond_for_report(fallback_location:) do |email|
      CsvReportEmailJob.perform_later(
        report_class.to_s, email, **report_args
      )
    end
  end

end
