# frozen_string_literal: true

class ArchivedEmailsController < ApplicationController
  include ActionView::Helpers::TextHelper

  before_action :authenticate_user!
  before_action :load_resources
  before_action :check_billing_access

  def show
    mail = Mail.new(@log_event.email_content)
    prepare_email_data(mail)
    render :show
  rescue StandardError
    redirect_with_error("show_error")
  end

  def download
    send_data(
      @log_event.email_content,
      filename: download_filename,
      type: "message/rfc822",
      disposition: "attachment"
    )
  end

  def download_attachment
    mail = Mail.new(@log_event.email_content)
    attachment_index = params[:index].to_i
    attachment = mail.attachments[attachment_index]

    if attachment
      send_data(
        attachment.body.decoded,
        filename: attachment.filename,
        type: attachment.content_type,
        disposition: "attachment"
      )
    else
      redirect_with_error("attachment_not_found")
    end
  end

  private

  def load_resources
    @log_event = LogEvent.find(params[:billing_log_event_id])

    raise ActiveRecord::RecordNotFound unless @log_event.email_file_present?
  end

  def current_facility
    @current_facility ||= @log_event&.facility || Facility.cross_facility
  end

  def redirect_with_error(error_key)
    flash[:error] = text(error_key)
    redirect_back(fallback_location: billing_log_events_path)
  end

  def prepare_email_data(mail)
    @email_subject = mail.subject
    @email_from = format_addresses(mail.from)
    @email_to = format_addresses(mail.to)
    @email_cc = format_addresses(mail.cc)
    @email_bcc = format_addresses(mail.bcc)
    @email_date = mail.date
    @email_body = extract_body(mail)
    @attachments = mail.attachments.map do |attachment|
      {
        filename: attachment.filename,
        size: attachment.body.decoded.size,
        content_type: attachment.content_type
      }
    end
  end

  def extract_body(mail)
    if mail.multipart?
      mail.html_part.body.decoded.html_safe
    else
      mail.body.decoded.html_safe
    end
  end

  def format_addresses(addresses)
    Array(addresses).join(", ") if addresses.present?
  end

  def download_filename
    timestamp = @log_event.event_time.strftime("%Y%m%d_%H%M%S")
    event_type = @log_event.event_type.tr(".", "_")
    "#{event_type}_#{timestamp}.eml"
  end
end
