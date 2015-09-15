class Notifier < ActionMailer::Base
  include DateHelper
  add_template_helper ApplicationHelper
  add_template_helper TranslationHelper
  add_template_helper OrdersHelper

  default :from => Settings.email.from, :content_type => 'multipart/alternative'

  # Welcome user, login credentials.  CC to PI and Department Admin.
  # Who created the account.  How to update.
  def new_user(args)
    @user=args[:user]
    @password=args[:password]
    send_nucore_mail args[:user].email, t('notifier.new_user.subject')
  end

  # When a new chart string/PO/CC is added to CoreFac, an email is sent
  # out to the PI, Departmental Administrators, and that particular
  # account's administrator(s)
  def new_account(args)
    @user=args[:user]
    @account=args[:account]
    send_nucore_mail args[:user].email, t('notifier.new_account.subject')
  end

  # Changes to the user affecting the PI or department will alert their
  # PI, the Dept Admins, and Lab Manager.
  def user_update(args)
    @user=args[:user]
    @account=args[:account]
    @created_by=args[:created_by]
    send_nucore_mail @account.owner.user.email, t('notifier.user_update.subject')
  end

  # Any changes to the financial accounts will alert the PI(s), admin(s)
  # when it is not them making the change. Adding someone to any role of a
  # financial account as well. Roles: Order, Admin, PI.
  def account_update(args)
    @user=args[:user]
    @account=args[:account]
    send_nucore_mail args[:user].email, t('notifier.account_update.subject')
  end

  # Custom order forms send out a confirmation email when filled out by a
  # customer. Customer gets one along with PI/Admin/Lab Manager.
  def order_receipt(args)
    @user=args[:user]
    @order=args[:order]
    send_nucore_mail args[:user].email, t('notifier.order_receipt.subject')
  end

  def review_orders(args)
    @user = User.find(args[:user_id])
    @facility = Facility.find(args[:facility_id])
    @account = Account.find(args[:account_id])
    send_nucore_mail @user.email, t('notifier.review_orders.subject')
  end

  # Billing sends out the statement for the month. Appropriate users get
  # their version of usage.
  # args = :user, :account, :facility
  def statement(args)
    @user=args[:user]
    @facility=args[:facility]
    @account=args[:account]
    @statement=args[:statement]
    attach_statement_pdf
    send_nucore_mail args[:user].email, t('notifier.statement.subject')
  end

  def order_detail_status_change(order_detail, old_status, new_status, to)
    @order_detail = order_detail
    @old_status = old_status
    @new_status = new_status
    template = "order_status_changed_to_#{new_status.downcase_name}"
    send_nucore_mail to, t("notifier.#{template}.subject", :order_detail => order_detail, :user => order_detail.order.user, :product => order_detail.product), template
  end

  private

  def attach_statement_pdf
    attachments[statement_pdf.filename] = {
      mime_type: 'application/pdf',
      content: statement_pdf.render,
    }
  end

  def statement_pdf
    @statement_pdf ||= StatementPdfFactory.instance(@statement)
  end

  def send_nucore_mail(to, subject, template_name=nil)
    mail(:subject => subject, :to => Settings.email.fake.enabled ? Settings.email.fake.to : to, :template_name => template_name)
  end
end
