# frozen_string_literal: true

class FacilityAccountsReconciliationController < ApplicationController

  include DateHelper

  admin_tab :all
  layout "two_column"

  before_action :check_acting_as
  before_action :init_current_facility
  before_action :check_billing_access
  before_action :set_billing_navigation
  before_action :authorize_mark_unrecoverable, only: :update

  def index
    order_details = unreconciled_details
                    .joins(:account)
                    .where(accounts: { type: account_class.to_s })
                    .includes(:order, :product, :statement)

    if reconcile_by_statement?
      @statements = TransactionSearch::StatementSearcher.new(order_details).options
      return render :index_by_statement
    end

    @search_form = TransactionSearch::SearchForm.new(params[:search])

    @search = TransactionSearch::Searcher.new(
      current_facility,
      TransactionSearch::AccountSearcher,
      TransactionSearch::AccountOwnerSearcher,
      TransactionSearch::StatementSearcher,
    ).search(order_details, @search_form)

    @unreconciled_details = @search.order_details.paginate(page: params[:page])
  end

  def update
    return redirect_to([account_route.to_sym, :facility_accounts, redirect_params.merge(show_items: true)]) if params[:display_items]

    if reconcile_whole_statement? && (error = whole_statement_error)
      flash[:error] = error
      return redirect_to([account_route.to_sym, :facility_accounts, redirect_params])
    end

    reconciled_at = parse_iso_date(params[:reconciled_at])&.beginning_of_day
    reconciler = OrderDetails::Reconciler.new(
      unreconciled_details,
      order_detail_params,
      reconciled_at,
      update_params[:order_status],
      bulk_reconcile: update_params[:bulk_note_checkbox] == "1",
      bulk_note: update_params[:bulk_note],
      bulk_deposit_number: update_params[:bulk_deposit_number],
    )

    if reconciler.reconcile_all > 0
      count = reconciler.count
      ReconciliationLogService.new(reconciler.order_details, current_user).log_events
      flash[:notice] = "#{count} payment#{'s' unless count == 1} successfully updated" if count > 0
      redirect_to([account_route.to_sym, :facility_accounts, { show_items: params[:show_items] }])
    else
      flash[:error] = reconciler.full_errors.join("<br />").html_safe
      redirect_to([account_route.to_sym, :facility_accounts, redirect_params])
    end
  end

  private

  def set_billing_navigation
    @subnav = "billing_nav"
    @active_tab = "admin_billing"
  end

  def account_route
    Account.config.account_type_to_route(params[:account_type])
  end
  helper_method :account_route

  def account_class
    # This is coming in from the router, not the user, so it should be safe
    params[:account_type].constantize
  end
  helper_method :account_class

  def unreconciled_details
    OrderDetail.complete.statemented(current_facility)
  end

  def update_params
    params.permit(
      :order_status,
      :bulk_note_checkbox,
      :bulk_note,
      :bulk_deposit_number,
    )
  end

  def reconcile_by_statement?
    SettingsHelper.feature_on?("billing.two_tier_reconciliation") && params[:show_items].blank?
  end

  def reconcile_whole_statement?
    params[:reconcile_statement].present?
  end

  def whole_statement_error
    return text("facility_accounts_reconciliation.index_by_statement.statement_blank") if selected_statement_ids.blank?

    if SettingsHelper.feature_on?("billing.show_reconciliation_deposit_number") && update_params[:bulk_deposit_number].blank?
      text("facility_accounts_reconciliation.index_by_statement.deposit_number_blank")
    end
  end

  def selected_statement_ids
    Array(params.dig(:search, :statements)).compact_blank
  end

  def order_detail_params
    return params[:order_detail] unless reconcile_whole_statement?

    ids = unreconciled_details
          .joins(:account)
          .where(accounts: { type: account_class.to_s })
          .where(statement_id: selected_statement_ids)
          .ids

    ActionController::Parameters.new(ids.index_with { { selected: "1" } }.transform_keys(&:to_s))
  end

  def authorize_mark_unrecoverable
    return unless params[:order_status] == "unrecoverable"

    authorize!(:mark_unrecoverable, OrderDetail)
  end

  def redirect_params
    {
      search: params[:search]&.permit!,
      page: params[:page],
      show_items: params[:show_items]
    }
  end
end
