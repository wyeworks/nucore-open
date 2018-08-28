# frozen_string_literal: true

class FacilityStatementsController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action { @facility = current_facility }

  load_and_authorize_resource class: Statement

  layout lambda {
    action_name.in?(%w(new)) ? "two_column_head" : "two_column"
  }

  def initialize
    @active_tab = "admin_billing"
    super
  end

  # GET /facilities/:facility_id/statements
  def index
    statements = current_facility.cross_facility? ? Statement.all : current_facility.statements
    @statements = statements.order(created_at: :desc).paginate(page: params[:page])
  end

  # GET /facilities/:facility_id/statements/new
  def new
    order_details = OrderDetail.need_statement(@facility)
    @order_detail_action = :create

    defaults = SettingsHelper.feature_on?(:set_statement_search_start_date) ? { date_range_start: format_usa_date(1.month.ago.beginning_of_month) } : {}
    @search_form = TransactionSearch::SearchForm.new(params[:search], defaults: defaults)
    @search = TransactionSearch::Searcher.search(order_details, @search_form)
    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details
  end

  # POST /facilities/:facility_id/statements
  def create
    @statement_creator = StatementCreator.new(order_detail_ids: params[:order_detail_ids], session_user: session_user, current_facility: current_facility)

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

  # GET /facilities/:facility_id/statements/:id
  def show
    @statement = Statement.find(params[:id])
  end

  private

  def success_message
    SettingsHelper.feature_on?(:send_statement_emails) ? "success_with_email_html" : "success_html"
  end

end
