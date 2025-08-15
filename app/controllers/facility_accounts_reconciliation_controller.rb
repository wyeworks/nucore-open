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
      bulk_note: update_params[:bulk_note],
      bulk_deposit_number: update_params[:bulk_deposit_number],
    )

    if reconciler.reconcile_all > 0
      count = reconciler.count
      log_reconciliation_events(reconciler.order_details)
      flash[:notice] = "#{count} payment#{'s' unless count == 1} successfully updated" if count > 0
      redirect_to([account_route.to_sym, :facility_accounts])
    else
      flash[:error] = reconciler.full_errors.join("<br />").html_safe
      redirect_to([account_route.to_sym, :facility_accounts, redirect_params])
    end
  end

  private

  def log_reconciliation_events(order_details)
    if SettingsHelper.feature_on?(:billing_log_events)
      log_events_with_notes(order_details)
    else
      log_events_without_notes(order_details)
    end
  end

  def log_events_with_notes(order_details)
    order_details_by_statement = order_details.group_by(&:statement)

    order_details_by_statement.each do |statement, statement_order_details|
      metadata = build_reconciliation_metadata(statement_order_details)
      LogEvent.log(statement, :closed, current_user, metadata: metadata)
    end
  end

  def log_events_without_notes(order_details)
    statements = Set.new
    order_details.each { |od| statements << od.statement }

    statements.each do |statement|
      LogEvent.log(statement, :closed, current_user)
    end
  end

  def build_reconciliation_metadata(order_details)
    metadata = {}

    reconciled_notes = extract_notes(order_details, "Reconciled", :reconciled_note)
    unrecoverable_notes = extract_notes(order_details, "Unrecoverable", :unrecoverable_note)

    metadata[:reconciled_notes] = reconciled_notes if reconciled_notes.any?
    metadata[:unrecoverable_notes] = unrecoverable_notes if unrecoverable_notes.any?

    metadata
  end

  def extract_notes(order_details, status_name, note_field)
    order_details
      .select { |od| od.order_status.name == status_name }
      .filter_map { |od| od.send(note_field) }
      .uniq
  end

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

  def authorize_mark_unrecoverable
    return unless params[:order_status] == "unrecoverable"

    authorize!(:mark_unrecoverable, OrderDetail)
  end

  def redirect_params
    {
      search: params[:search]&.permit!,
      page: params[:page]
    }
  end
end
