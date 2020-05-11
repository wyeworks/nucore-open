# frozen_string_literal: true

class StatementCreator

  attr_accessor :order_detail_ids, :errors, :to_statement, :account_statements, :session_user, :current_facility

  def initialize(params)
    @order_detail_ids = params[:order_detail_ids]
    @session_user = params[:session_user]
    @current_facility = params[:current_facility]
    @errors = []
    @to_statement = {}
  end

  def create
    OrderDetail.transaction do
      set_order_details_to_statement
      setup_statement_from_details
      raise ActiveRecord::Rollback if errors.any?
    end
    errors.none?
  end

  def formatted_errors
    errors.join("<br/>").html_safe
  end

  def send_statement_emails
    if SettingsHelper.feature_on?(:send_statement_emails)
      account_statements.each do |account, statement|
        account.notify_users.each { |u| Notifier.statement(user: u, facility: statement.facility, account: account, statement: statement).deliver_later }
      end
    end
  end

  def account_list
    account_statements.map { |a, _s| a.account_list_item }
  end

  def formatted_account_list
    account_list.join("<br/>").html_safe
  end

  private

  def set_order_details_to_statement
    order_detail_ids.each do |order_detail_id|
      od = nil
      begin
        od = OrderDetail.need_statement(current_facility).readonly(false).find(order_detail_id)
        @to_statement[od.account] ||= []
        @to_statement[od.account] << od
      rescue => e
        @errors << I18n.t("controllers.facility_statements.order_error", order_detail_id: order_detail_id)
      end
    end
  end

  def setup_statement_from_details
    @account_statements = {}
    to_statement.each do |account, order_details|
      statement = Statement.create!(facility: order_details.first.facility, account_id: account.id, created_by: session_user.id)
      LogEvent.log(statement, :create, session_user)
      order_details.each do |od|
        StatementRow.create!(statement_id: statement.id, order_detail_id: od.id)
        od.statement_id = statement.id
        @errors << "#{od} #{od.errors}" unless od.save
      end
      @account_statements[account] = statement
    end
  end

end
