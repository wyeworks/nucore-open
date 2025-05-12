# frozen_string_literal: true

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
    @statements = @account.statements.uniq.paginate(page: params[:page])
  end

  # GET /accounts/:account_id/statements/:id
  def show
    action = "show"
    @active_tab = "accounts"

    respond_to do |format|
      format.pdf do
        @statement_pdf = StatementPdfFactory.instance(@statement, download: true)
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

  def init_statement
    @statement = Statement.find_by!(id: params[:id], account_id: @account.id)
    @facility = @statement.facility
  end

end
