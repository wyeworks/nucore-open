# frozen_string_literal: true

class StatementCreator

  attr_accessor :order_detail_ids, :errors, :to_statement, :account_statements, :session_user, :current_facility, :parent_invoice_number

  def initialize(params)
    @order_detail_ids = params[:order_detail_ids]
    @session_user = params[:session_user]
    @current_facility = params[:current_facility]
    @parent_invoice_number = params[:parent_invoice_number]
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
      account_statements.each do |_account, statement|
        statement.send_emails
      end
    end
  end

  def account_list
    account_statements.map { |account, _statement| account.account_list_item }
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
      statement_attrs = {
        facility: order_details.first.facility,
        account_id: account.id,
        created_by: session_user.id
      }

      if parent_invoice_number.present? && SettingsHelper.feature_on?(:reference_statement_invoice_number)
        # Parse invoice number format: "account_id-statement_id"
        if parent_invoice_number =~ /\A(?<account_id>\d+)-(?<statement_id>\d+)\z/
          account_id = Regexp.last_match[:account_id]
          statement_id = Regexp.last_match[:statement_id]

          parent_statement = Statement.find_by(id: statement_id)

          if parent_statement.present? && parent_statement.account_id == account_id
            statement_attrs[:parent_statement_id] = statement_id
          else
            @errors << I18n.t("services.statement_creator.parent_statement_not_found", invoice_number: parent_invoice_number)
          end
        else
          @errors << I18n.t("services.statement_creator.invalid_invoice_format")
        end
      end

      statement = Statement.create!(statement_attrs)
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
