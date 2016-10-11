class FacilityStatementsController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action { @facility = current_facility }

  load_and_authorize_resource class: Statement

  include TransactionSearch

  layout "two_column"

  def initialize
    @active_tab = "admin_billing"
    super
  end

  # GET /facilities/:facility_id/statements
  def index
    statements = current_facility.cross_billing? ? Statement.all : current_facility.statements
    @statements = statements.order(created_at: :desc).paginate(page: params[:page])
  end

  # GET /facilities/:facility_id/statements/new
  def new_with_search
    @order_details = current_facility.cross_billing? ? @order_details.need_any_statement : @order_details.need_statement(@facility)
    @order_detail_action = :send_statements
    set_default_start_date if SettingsHelper.feature_on?(:set_statement_search_start_date)
    @layout = "two_column_head"
  end

  # POST /facilities/:facility_id/statements/send_statements
  def send_statements
    if params[:order_detail_ids].nil? || params[:order_detail_ids].empty?
      flash[:error] = I18n.t "controllers.facility_statements.send_statements.no_selection"
      redirect_to action: :new
      return
    end
    @errors = []
    to_statement = {}
    OrderDetail.transaction do
      params[:order_detail_ids].each do |order_detail_id|
        od = nil
        begin
          ods = current_facility.cross_billing? ? OrderDetail.need_any_statement : OrderDetail.need_statement(current_facility)
          od = ods.readonly(false).find(order_detail_id)
          to_statement[od.account] ||= []
          to_statement[od.account] << od
        rescue => e
          @errors << I18n.t("controllers.facility_statements.send_statements.order_error", order_detail_id: order_detail_id)
        end
      end

      @account_statements = {}
      to_statement.each do |account, order_details|
        statement = Statement.create!(facility: order_details.first.facility, account_id: account.id, created_by: session_user.id)
        order_details.each do |od|
          StatementRow.create!(statement_id: statement.id, order_detail_id: od.id)
          od.statement_id = statement.id
          @errors << "#{od} #{od.errors}" unless od.save
        end
        @account_statements[account] = statement
      end

      if @errors.any?
        flash[:error] = I18n.t("controllers.facility_statements.errors_html", errors: @errors.join("<br/>")).html_safe
        raise ActiveRecord::Rollback
      else
        @account_statements.each do |account, statement|
          account.notify_users.each { |u| Notifier.delay.statement(user: u, facility: statement.facility, account: account, statement: statement) }
        end
        account_list = @account_statements.map { |a, _s| a.account_list_item }
        flash[:notice] = I18n.t("controllers.facility_statements.send_statements.success_html", accounts: account_list.join("<br/>")).html_safe
      end
    end
    redirect_to action: "new"
  end

  # GET /facilities/:facility_id/statements/:id
  def show
    @statement = Statement.find(params[:id])
  end

end
