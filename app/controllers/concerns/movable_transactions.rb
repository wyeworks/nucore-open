# frozen_string_literal: true

module MovableTransactions

  extend ActiveSupport::Concern

  included do
    before_action :load_order_details, only: [:confirm_transactions, :move_transactions, :reassign_chart_strings]
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
    redirect_to_movable_transactions
  end

  def get_movable_transactions(account)
    @order_details.find_all do |order_detail|
      order_detail.can_be_assigned_to_account?(account)
    end
  end

  def movable_transactions
    @search_form = TransactionSearch::SearchForm.new(params[:search])
    @search = TransactionSearch::Searcher.billing_search(
      movable_transactions_order_details,
      @search_form,
      include_facilities: include_facilities?,
    )
    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details.reorder(sort_clause).paginate(page: params[:page], per_page: 100)

    @order_detail_action = :reassign_chart_strings
  end

  private

  def ensure_order_details_selected
    if @order_details.count < 1
      flash[:alert] = I18n.t("controllers.facilities.bulk_reassignment.no_transactions_selected")
      redirect_to_movable_transactions
    end
  end

  def load_transactions
    @selected_account = Account.find(params[:chart_string_reassignment_form][:account_id])
    @movable_transactions = get_movable_transactions(@selected_account)
    @unmovable_transactions = @order_details - @movable_transactions
  end

  def bulk_reassignment_success
    flash[:notice] = I18n.t("controllers.facilities.bulk_reassignment.move.success", count: @order_details.count)
  end

  def bulk_reassignment_failure(reassignment_error)
    flash[:alert] = I18n.t("controllers.facilities.bulk_reassignment.move.failure",
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

  def movable_transactions_order_details
    raise NotImplementedError
  end

  def redirect_to_movable_transactions
    raise NotImplementedError
  end

end
