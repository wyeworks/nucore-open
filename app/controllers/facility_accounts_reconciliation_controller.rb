# frozen_string_literal: true

class FacilityAccountsReconciliationController < ApplicationController

  include DateHelper

  admin_tab :all
  layout "two_column"

  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :check_billing_access
  before_action :check_billing_access_to_mark_as_unrecoverable
  before_action :set_billing_navigation

  def index
    order_details = unreconciled_details
                    .joins(:account)
                    .where(accounts: { type: account_class.to_s })
                    .includes(:order, :product, :statement)

    @search_form = TransactionSearch::SearchForm.new(params[:search])

    @search = TransactionSearch::Searcher.new(
      TransactionSearch::AccountSearcher,
      TransactionSearch::AccountOwnerSearcher,
      TransactionSearch::StatementSearcher,
    ).search(order_details, @search_form)

    @unreconciled_details = @search.order_details.paginate(page: params[:page])
  end

  def update
    reconciled_at = parse_usa_date(params[:reconciled_at])
    reconciler = OrderDetails::Reconciler.new(
      unreconciled_details,
      params[:order_detail],
      reconciled_at,
      update_params[:order_status],
      bulk_reconcile: update_params[:bulk_note_checkbox] == "1",
      **update_params.slice(
        :bulk_note,
        :bulk_deposit_number,
        :bulk_unrecoverable_note,
      ),
    )

    if reconciler.reconcile_all > 0
      count = reconciler.count
      statements = Set.new
      reconciler.order_details.each { |od| statements << od.statement }

      statements.each do |statement|
        LogEvent.log(statement, :closed, current_user)
      end

      flash[:notice] = "#{count} payment#{count == 1 ? '' : 's'} successfully updated" if count > 0
    else
      flash[:error] = reconciler.full_errors.join("<br />").html_safe
    end

    redirect_to([account_route.to_sym, :facility_accounts])
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
      :bulk_unrecoverable_note,
    )
  end

  def check_billing_access_to_mark_as_unrecoverable
    if params[:order_status] == "unrecoverable" && !(current_user.administrator? || current_user.global_billing_administrator?)
      flash[:error] = t("controllers.facility_accounts_reconciliation.cannot_mark_as_unrecoverable")
      redirect_to([account_route.to_sym, :facility_accounts])
    end
  end
end
