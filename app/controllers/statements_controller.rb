class StatementsController < ApplicationController

  customer_tab  :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_account
  before_action :init_statement, only: [:show]

  load_and_authorize_resource

  def initialize
    @active_tab = "accounts"
    super
  end

  # GET /accounts/:id/statements
  def index
    @order_details = @account.order_details.has_statement.by_statemented_at
    @date_range_field = "journal_or_statement_date"
  end

  # GET /accounts/:account_id/statements/:id
  def show
    action = "show"
    @active_tab = "accounts"

    respond_to do |format|
      format.pdf do
        @statement_pdf = StatementPdfFactory.instance(@statement, params[:show].blank?)
        render action: "show"
      end
    end
  end

  private

  def ability_resource
    @account
  end

  def init_account
    # CanCan will make sure that we're authorizing the account
    @account = Account.find(params[:account_id])
  end

  #
  # Override CanCan's find -- it won't properly search by 'recent'
  def init_statement
    @statement = @account.statements.find(params[:id])
    @facility = @statement.facility
  end

end
