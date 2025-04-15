# frozen_string_literal: true

class VoucherSplitsReconciliationController < ApplicationController

  include DateHelper
  helper UmassCorum::VoucherSplitHelper

  admin_tab :all
  layout "two_column"

  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :check_billing_access
  before_action :set_billing_navigation

  def pending
    load_unreconciled_details_for_status(OrderStatus.complete)
  end

  def index
    load_unreconciled_details_for_status(UmassCorum::VoucherOrderStatus.mivp)
  end

  def update
    reconcile_all = params[:reconcile_all] == "true"

    if reconcile_form_request?
      UmassCorum::VoucherReconciler.add_all_order_details_to_params(unreconciled_details_scope, params[:order_detail], "reconciled") if reconcile_all

      reconciled_at = parse_usa_date(params[:reconciled_at])

      reconciler = OrderDetails::Reconciler.new(
        unreconciled_details_scope,
        params[:order_detail],
        reconciled_at,
        "reconciled",
        bulk_reconcile: params[:bulk_note_checkbox] == "1",
        bulk_note: params[:bulk_note],
        bulk_deposit_number: params[:bulk_deposit_number],
      )
      redirect_route = voucher_splits_path
    else
      UmassCorum::VoucherReconciler.add_all_order_details_to_params(unreconciled_details_scope, params[:order_detail], "mivp_pending") if reconcile_all

      reconciler = UmassCorum::VoucherReconciler.new(unreconciled_details_scope, params[:order_detail], params[:bulk_reconcile_note], params[:bulk_note_checkbox])
      redirect_route = voucher_splits_mivp_pending_path
    end

    if reconciler.reconcile_all > 0
      count = reconciler.count
      flash[:notice] = "#{count} payment#{count == 1 ? '' : 's'} successfully #{params[:reconciled_at] ? 'reconciled' : 'marked MIVP pending'}" if count > 0
    else
      flash[:error] = reconciler.full_errors.join("<br />").html_safe
    end

    redirect_to redirect_route
  end

  private

  def set_billing_navigation
    @subnav = "billing_nav"
    @active_tab = "admin_billing"
  end

  def account_class
    UmassCorum::VoucherSplitAccount
  end
  helper_method :account_class

  def reconcile_form_request?
    params[:commit] == "Update Orders"
  end

  # Includes Complete and MIVP Pending
  def unreconciled_details_scope
    OrderDetail.complete.statemented(current_facility)
  end

  def load_unreconciled_details_for_status(order_status)
    order_details = unreconciled_details_scope
                    .joins(:account)
                    .where(accounts: { type: account_class.to_s })
                    .where(order_status: order_status)
                    .includes(:order, :product, :statement, :account)

    @search_form = TransactionSearch::SearchForm.new(params[:search])

    @search = TransactionSearch::Searcher.new(
      TransactionSearch::AccountSearcher,
      TransactionSearch::AccountOwnerSearcher,
      TransactionSearch::StatementSearcher,
    ).search(order_details, @search_form)

    @unreconciled_details = @search.order_details.paginate(page: params[:page], per_page: 150)
  end

end
