# frozen_string_literal: true

class Notifier < ActionMailer::Base

  include DateHelper
  helper ApplicationHelper
  helper ViewHookHelper

  default from: Settings.email.from, content_type: "multipart/alternative"

  # Welcome user, login credentials
  def new_user(user:, password:)
    attachments.inline["email_logo.png"] = File.read("#{Rails.root}#{Settings.email_logo_path}") if Settings.email_logo_path.present?
    @user = user
    @password = password
    send_nucore_mail @user.email, text("views.notifier.new_user.subject")
  end

  # Changes to the user affecting the PI or department will alert their
  # PI, the Dept Admins, and Lab Manager.
  def user_update(args)
    @user = args[:user]
    @account = args[:account]
    @created_by = args[:created_by]
    @role = AccountUserPresenter.localized_role(args[:role])
    send_to = args[:send_to]
    send_nucore_mail send_to, text("views.notifier.user_update.subject", user: @user)
  end

  # Any changes to the financial accounts will alert the PI(s), admin(s)
  # when it is not them making the change. Adding someone to any role of a
  # financial account as well. Roles: Order, Admin, PI.
  def account_update(args)
    @user = args[:user]
    @account = args[:account]
    send_nucore_mail args[:user].email, text("views.notifier.account_update.subject")
  end

  def review_orders(user:, accounts:, facility: Facility.cross_facility)
    @user = user
    @accounts = accounts
    @facility = facility

    @contact_message = if facility.email
                         "please email [#{facility.email}](mailto:#{facility.email})."
                       else
                         "please contact the facility administrator."
                       end

    @accounts_grouped_by_owner = accounts.group_by(&:owner_user)
    send_nucore_mail(
      @user.email,
      text("views.notifier.review_orders.subject", abbreviation: @facility.abbreviation)
    ).tap { |email| log_review_orders_email(email) }
  end

  # Billing sends out the statement for the month. Appropriate users get
  # their version of usage.
  # args = :user, :account, :facility
  def statement(args)
    @user = args[:user]
    @facility = args[:facility]
    @account = args[:account]
    @statement = args[:statement]
    attach_statement_pdf
    send_nucore_mail(
      args[:user].email,
      text("views.notifier.statement.subject", facility: @facility),
      nil,
      Settings.email.invoice_bcc
    ).tap { |email| log_statement_email(email) }
  end

  def order_detail_status_changed(order_detail)
    @order_detail = order_detail
    facility = order_detail.facility.abbreviation
    status = order_detail.order_status.name
    mail(
      to: order_detail.order.user.email,
      subject: text("views.notifier.order_detail_status_changed.subject", facility: facility, status: status)
    )
  end

  private

  def attach_statement_pdf
    attachments[statement_pdf.filename] = {
      mime_type: "application/pdf",
      content: statement_pdf.render,
    }
  end

  def statement_pdf
    @statement_pdf ||= StatementPdfFactory.instance(@statement)
  end

  def send_nucore_mail(to, subject, template_name = nil, bcc = nil)
    mail(subject: subject, to: to, template_name: template_name, bcc: bcc)
  end

  def log_review_orders_email(email)
    return unless SettingsHelper.feature_on?(:billing_log_events)

    accounts = @accounts.map(&:description).join(", ")

    LogEvent.log_email(
      @user,
      :review_orders_email,
      email,
      metadata: {
        object: accounts,
        accounts_ids: @accounts.map(&:id),
        facility_id: @facility.id,
      },
    )
  end

  def log_statement_email(email)
    return unless SettingsHelper.feature_on?(:billing_log_events)

    LogEvent.log_email(
      @statement,
      :statement_email,
      email,
      metadata: {
        facility_id: @facility&.id
      },
    )
  end

end
