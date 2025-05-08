# frozen_string_literal: true

class FacilityStatementsController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action { @facility = current_facility }
  before_action :enable_sorting, only: [:new]

  load_and_authorize_resource class: Statement

  layout lambda {
    action_name.in?(%w(new)) ? "two_column_head" : "two_column"
  }

  include CsvEmailAction
  include SortableBillingTable

  def initialize
    @active_tab = "admin_billing"
    super
  end

  # GET /facilities/:facility_id/statements
  def index
    search_params = permitted_search_params.merge(current_facility:)

    @search_form = StatementSearchForm.new(search_params)
    @statements = @search_form.search.order(created_at: :desc).includes(:closed_events, :order_details)

    respond_to do |format|
      format.html { @statements = @statements.paginate(page: params[:page]) }
      format.csv do
        yield_email_and_respond_for_report do |email|
          StatementSearchResultMailer.search_result(email, search_params.to_h).deliver_later
        end
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
    @search = TransactionSearch::Searcher.billing_search(order_details, @search_form, include_facilities: current_facility.cross_facility?)
    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details.reorder(sort_clause)
  end

  # POST /facilities/:facility_id/statements
  def create
    @statement_creator = StatementCreator.new(order_detail_ids: params[:order_detail_ids], session_user:, current_facility:)

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

  # POST /facilities/:facility_id/statements/download_selected
  def download_selected
    if params[:statement_ids].blank?
      flash[:error] = I18n.t("statements.no_statements_selected")
      redirect_to facility_statements_path(@facility)
      return
    end

    statement_ids = params[:statement_ids]
    statements = Statement.where(id: statement_ids)

    StatementPdfDownloader.new(statements).handle_download_response(
      self,
      facility_statements_path(@facility)
    )
  end

  private

  def success_message
    SettingsHelper.feature_on?(:send_statement_emails) ? "success_with_email_html" : "success_html"
  end

end
