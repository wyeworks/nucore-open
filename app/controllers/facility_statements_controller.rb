# frozen_string_literal: true

class FacilityStatementsController < ApplicationController

  admin_tab     :all
  before_action :check_acting_as
  before_action { @facility = current_facility }
  before_action :enable_sorting, only: [:new]

  load_and_authorize_resource class: Statement

  layout lambda {
    action_name.in?(%w(new)) ? "two_column_head" : "two_column"
  }

  include CsvEmailAction
  include SortableBillingTable

  helper_method :can_set_invoice_date?

  def initialize
    @active_tab = "admin_billing"
    super
  end

  # GET /facilities/:facility_id/statements
  def index
    respond_to do |format|
      format.html do
        search_params = permitted_search_params.merge(current_facility:)
        @search_form = StatementSearchForm.new(search_params)
        @statements = @search_form.search.order(created_at: :desc).includes(:closed_events, :order_details)

        @statements = @statements.paginate(page: params[:page])
      end

      format.csv do
        search_params = permitted_search_params.to_h
        search_params[:current_facility] = current_facility.url_name

        queue_csv_report_email(Reports::StatementSearchReport, search_params:)
      end
    end
  end

  def permitted_search_params
    (params[:statement_search_form] || empty_params).permit(:date_range_start, :date_range_end, :status, accounts: [], account_admins: [], facilities: [])
  end

  # GET /facilities/:facility_id/statements/new
  def new
    order_details = OrderDetail.need_statement(@facility)
    @order_detail_action = :create

    defaults = SettingsHelper.feature_on?(:set_statement_search_start_date) ? { date_range_start: format_usa_date(1.month.ago.beginning_of_month) } : {}
    @search_form = TransactionSearch::SearchForm.new(params[:search], defaults:)
    @search =
      TransactionSearch::Searcher
      .new(facilities: current_facility.cross_facility?)
      .search(order_details, @search_form)

    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details.reorder(sort_clause)
  end

  # POST /facilities/:facility_id/statements
  def create
    creator_params = {
      order_detail_ids: params[:order_detail_ids],
      session_user:,
      current_facility:,
      parent_invoice_number: params[:parent_invoice_number]
    }

    if can_set_invoice_date? && params[:invoice_date].present?
      creator_params[:invoice_date] = params[:invoice_date]
    end

    @statement_creator = StatementCreator.new(creator_params)

    if @statement_creator.order_detail_ids.blank?
      flash[:error] = text("no_selection")
    elsif @statement_creator.create
      @statement_creator.send_statement_emails
      flash[:notice] = text(success_message, accounts: @statement_creator.formatted_account_list)

    else
      flash[:error] = text("errors_html", errors: @statement_creator.formatted_errors)
    end

    redirect_to action: :new
  end

  # POST /facilities/:facility_id/statements/:id/resend_emails
  def resend_emails
    if SettingsHelper.feature_on?(:send_statement_emails)
      statement = Statement.find(params[:id])
      statement.send_emails
      flash[:notice] = text("success_with_email_html", accounts: statement.account)
    end
    redirect_to action: :index
  end

  # POST /facilities/:facility_id/statements/:id/cancel
  def cancel
    statement = Statement.find(params[:id])

    statement.canceled_at = Time.current

    if statement.save
      OrderDetail.where(statement_id: statement.id).update_all(statement_id: nil)
      LogEvent.log(statement, :closed, current_user)
      flash[:notice] = text("cancel_success")
    else
      flash[:error] = text("cancel_fail")
    end

    redirect_to action: :index
  end

  # GET /facilities/:facility_id/statements/:id
  def show
    @statement = Statement.find(params[:id])
  end

  private

  def success_message
    SettingsHelper.feature_on?(:send_statement_emails) ? "success_with_email_html" : "success_html"
  end

  def can_set_invoice_date?
    session_user.administrator? || session_user.global_billing_administrator?
  end

end
