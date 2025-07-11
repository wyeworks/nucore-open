# frozen_string_literal: true

class TransactionsController < ApplicationController

  customer_tab :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :enable_sorting, only: [:index, :in_review]
  before_action :load_order_details, only: [:confirm_transactions, :move_transactions, :reassign_chart_strings]
  before_action :authorize_movable_transactions, only: [:movable_transactions, :reassign_chart_strings, :confirm_transactions, :move_transactions]

  include OrderDetailsCsvExport
  include SortableBillingTable

  def initialize
    @active_tab = "accounts"
    super
  end

  def index
    order_details = current_user.administered_order_details.joins(:order)
    @export_enabled = true

    @search_form = TransactionSearch::SearchForm.new(
      params[:search],
      defaults: {
        date_range_start: format_usa_date(1.month.ago.beginning_of_month),
      },
    )

    @search = TransactionSearch::Searcher.billing_search(order_details, @search_form, include_facilities: true)
    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details.reorder(sort_clause)

    respond_to do |format|
      format.html { @order_details = @order_details.paginate(page: params[:page]) }
      format.csv { handle_csv_search }
    end
  end

  def in_review
    @recently_reviewed = current_user.administered_order_details.recently_reviewed.paginate(page: params[:page])
    order_details = current_user.administered_order_details.in_review

    @export_enabled = true

    @search_form = TransactionSearch::SearchForm.new(params[:search])
    @search = TransactionSearch::Searcher.billing_search(order_details, @search_form, include_facilities: true)

    @date_range_field = @search_form.date_params[:field]
    params[:sort] = "date_range_field" if params[:sort].nil? # set default sort column
    @order_details = @search.order_details.reorder(sort_clause)

    @extra_date_column = :reviewed_at
    @order_detail_action = :mark_as_reviewed
    @order_detail_link = {
      text: text("shared.dispute"),
      display?: proc { |order_detail| order_detail.can_dispute? },
      proc: proc { |order_detail| order_order_detail_path(order_detail.order, order_detail) },
    }
    respond_to do |format|
      format.html
      format.csv { handle_csv_search }
    end
  end

  def movable_transactions
    @search_form = TransactionSearch::SearchForm.new(params[:search])
    @search = TransactionSearch::Searcher.billing_search(
      order_details = current_user.administered_order_details.all_movable,
      @search_form,
      include_facilities: true,
    )
    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details.reorder(sort_clause).paginate(page: params[:page], per_page: 100)

    @order_detail_action = :reassign_chart_strings
  end

  def reassign_chart_strings
    ensure_order_details_selected
    initialize_chart_string_reassignment_form
  end

  def confirm_transactions
    load_transactions
    initialize_chart_string_reassignment_form
  end

  def move_transactions
    begin
      reassign_account_from_params!
      bulk_reassignment_success
    rescue ActiveRecord::RecordInvalid => e
      bulk_reassignment_failure(e)
    end
    redirect_to movable_transactions_transactions_path
  end

  def mark_as_reviewed
    if params[:order_detail_ids].nil? || params[:order_detail_ids].empty?
      flash[:error] = I18n.t "controllers.facility_notifications.no_selection"
    else
      @errors = []
      @order_details_updated = []
      params[:order_detail_ids].each do |order_detail_id|
        begin
          od = OrderDetail.readonly(false).find(order_detail_id)
          od.reviewed_at = Time.zone.now
          od.save!
          LogEvent.log(od, :review, current_user)
          @order_details_updated << od
        rescue => e
          logger.error(e.message)
          @errors << order_detail_id
        end
      end
      flash[:notice] = I18n.t("controllers.facility_notifications.mark_as_reviewed.success") if @order_details_updated.any?
      flash[:error] = I18n.t("controllers.facility_notifications.mark_as_reviewed.errors", errors: @errors.join(", ")) if @errors.any?
    end
    redirect_to action: :in_review
  end

  private

  def authorize_movable_transactions
    authorize! :movable_transactions, TransactionsController
  end

  def ensure_order_details_selected
    if @order_details.count < 1
      flash[:alert] = I18n.t("controllers.facilities.bulk_reassignment.no_transactions_selected")
      redirect_to movable_transactions_transactions_path
    end
  end

  def initialize_chart_string_reassignment_form
    @chart_string_reassignment_form = ChartStringReassignmentForm.new(@order_details, current_user)
    @date_range_field = "journal_or_statement_date"
  end

  def load_transactions
    @selected_account = Account.find(params[:chart_string_reassignment_form][:account_id])
    @movable_transactions = get_movable_transactions(@selected_account)
    @unmovable_transactions = @order_details - @movable_transactions
  end

  def get_movable_transactions(account)
    @order_details.find_all do |order_detail|
      order_detail.can_be_assigned_to_account?(account)
    end
  end

  def bulk_reassignment_success
    flash.now[:notice] = I18n.t("controllers.facilities.bulk_reassignment.move.success", count: @order_details.count)
  end

  def bulk_reassignment_failure(reassignment_error)
    flash.now[:alert] = I18n.t("controllers.facilities.bulk_reassignment.move.failure",
                               reassignment_error: reassignment_error,
                               order_detail_id: reassignment_error.record.id)
  end

  def reassign_account_from_params!
    account = Account.find(params[:account_id])
    OrderDetail.reassign_account!(account, @order_details)
  end

  def load_order_details
    @order_details = OrderDetail.where(id: params[:order_detail_ids])
  end

end
