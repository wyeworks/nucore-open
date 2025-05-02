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

  # POST /accounts/:account_id/statements/download_selected
  def download_selected
    if params[:statement_ids].blank?
      flash[:error] = I18n.t("statements.no_statements_selected")
      redirect_to account_statements_path(@account)
      return
    end

    statement_ids = params[:statement_ids]
    @statements = @account.statements.where(id: statement_ids)
    @pdfs = StatementPdfDownloader.new(@statements).download_all

    # Direct download for single PDF
    if @pdfs.length == 1 && request.format != :js
      send_data @pdfs.first[:data],
                filename: @pdfs.first[:filename],
                type: 'application/pdf',
                disposition: 'attachment'
      return
    end

    respond_to do |format|
      format.js # Renders download_selected.js.erb

      format.html do
        flash[:notice] = I18n.t("statements.downloading_multiple", count: @pdfs.length)
        redirect_back(fallback_location: account_statements_path(@account))
      end

      format.json do
        simplified_pdfs = @pdfs.map do |pdf|
          {
            filename: pdf[:filename],
            data: Base64.strict_encode64(pdf[:data])
          }
        end
        render json: { pdfs: simplified_pdfs }
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
