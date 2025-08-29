# frozen_string_literal: true

class ArchivedEmailsController < ApplicationController
  include ActionView::Helpers::TextHelper

  before_action :authenticate_user!
  before_action :load_resources
  before_action :authorize_access

  def show
    mail = Mail.new(@archived_email.email_content)
    prepare_email_data(mail)
    render :show
  rescue StandardError
    redirect_with_error("show.error")
  end

  def download
    send_data(
      @archived_email.email_content,
      filename: download_filename,
      type: "message/rfc822",
      disposition: "attachment"
    )
  rescue StandardError
    redirect_with_error("download.error")
  end

  def download_attachment
    mail = Mail.new(@archived_email.email_content)
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
  rescue StandardError
    redirect_with_error("download.error")
  end

  private

  def load_resources
    @log_event = LogEvent.find(params[:billing_log_event_id])
    @archived_email = @log_event.archived_email

    redirect_with_error("not_found") unless @archived_email&.email_file_present?
  rescue ActiveRecord::RecordNotFound
    redirect_with_error("log_event_not_found")
  end

  def authorize_access
    return unless @log_event && @archived_email

    facility = @log_event.facility
    ability = Ability.new(current_user, facility || Facility.cross_facility, self)

    authorized = current_user.administrator? ||
                 current_user.global_billing_administrator? ||
                 (facility && ability.can?(:manage_billing, facility))

    redirect_with_error("unauthorized") unless authorized
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
