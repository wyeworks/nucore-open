class StatementsController < ApplicationController
  customer_tab  :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_account
  before_action :init_statement

  load_and_authorize_resource

  def initialize
    @active_tab = 'accounts'
    super
  end

  # GET /accounts/:account_id/facilities/:facility_id/statements/:id
  def show
    action='show'
    @active_tab = 'accounts'

    case params[:id]
    when 'recent'
        @order_details = @account.order_details.for_facility_with_price_policy(@facility)
        @order_details = @order_details.paginate(:page => params[:page])
    when 'list'
        action='list'
        @statements=@statements.paginate(:page => params[:page])
    end

    respond_to do |format|
      format.html { render :action => action }
      format.pdf do
        @statement_pdf = StatementPdfFactory.instance(@statement, params[:show].blank?)
        render action: 'show'
      end
    end
  end

  private

  def ability_resource
    return @account
  end

  def init_account
    # CanCan will make sure that we're authorizing the account
    @account = Account.find(params[:account_id])
  end

  #
  # Override CanCan's find -- it won't properly search by 'recent'
  def init_statement
    @facility = Facility.find_by_url_name!(params[:facility_id])
    @statements = @account.statements.where(facility_id: @facility.id)

    @statement = if params[:id] =~ /\w+/i
      @statements.blank? ? Statement.find_by_facility_id(@facility.id) : @statements.first
                 else
      @account.statements.find(params[:id])
                 end
    @statement = Statement.new if @statement.nil?
  end

end
