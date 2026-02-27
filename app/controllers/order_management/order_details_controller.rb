# frozen_string_literal: true

class OrderManagement::OrderDetailsController < ApplicationController

  include OrderDetailFileDownload

  load_resource :facility, find_by: :url_name

  load_resource :order, through: :facility, except: [:files, :template_results]
  load_resource :order_detail, through: :order, except: [:files, :template_results]
  # We can't load through the facility because of cross-core orders
  before_action :init_order_detail, only: [:files, :template_results]

  helper_method :edit_disabled?, :actual_cost_edit_disabled?

  before_action :authorize_order_detail, except: %i(sample_results)
  before_action :authorize_mark_unrecoverable, only: :update
  before_action :load_accounts, only: [:edit, :update]
  before_action :load_order_statuses, only: [:edit, :update]

  admin_tab :all

  # GET /facilities/:facility_id/orders/:order_id/order_details/:id/manage
  def edit
    @active_tab = "admin_orders"
    render layout: false if modal?
  end

  # PUT /facilities/:facility_id/orders/:order_id/order_details/:id/manage
  def update
    @active_tab = "admin_orders"

    updater = OrderDetails::ParamUpdater.new(
      @order_detail,
      user: session_user,
      cancel_fee: params[:with_cancel_fee] == "1"
    )

    if updater.update_param_attributes(update_params)
      flash[:notice] = text("update.success")
      flash[:alert] = text("update.success_with_missing_actuals", order: @order_detail) if @order_detail.requires_but_missing_actuals?
      if @order_detail.updated_children.any?
        flash[:notice] = text("update.success_with_auto_scaled")
        flash[:updated_order_details] = @order_detail.updated_children.map(&:id)
      end
      if modal?
        head :ok
      else
        redirect_to [current_facility, @order]
      end
    else
      flash.now[:error] = text("update.error")
      render :edit, layout: !modal?, status: 406
    end
  end

  # GET /facilities/:facility_id/orders/:order_id/order_details/:id/pricing
  def pricing
    checker = OrderDetails::PriceChecker.new(@order_detail, user: session_user)
    @prices = checker.prices_from_params(params[:order_detail] || empty_params)

    render json: @prices.to_json
  end

  # GET /facilities/:facility_id/orders/:order_id/order_details/:id/files
  def files
    @files = @order_detail.stored_files.sample_result.order(:created_at)
    render layout: false if modal?
  end

  # POST /facilities/:facility_id/orders/:order_id/order_details/:id/remove_from_journal
  def remove_from_journal
    OrderDetailJournalRemover.remove_from_journal(@order_detail)

    flash[:notice] = text("remove_from_journal.notice")
    if modal?
      head :ok
    else
      redirect_to [current_facility, @order]
    end
  end

  private

  def modal?
    request.xhr?
  end
  helper_method :modal?

  def ability_resource
    @order_detail
  end

  def authorize_order_detail
    authorize! :update, @order_detail
  end

  def load_accounts
    @available_accounts = @order_detail.available_accounts.to_a
    @available_accounts << @order.account unless @available_accounts.include?(@order.account)
  end

  def load_order_statuses
    return if @order_detail.reconciled?

    if @order_detail.complete?
      @order_statuses = OrderStatus.by_names([
        OrderStatus::COMPLETE,
        OrderStatus::CANCELED,
        OrderStatus::UNRECOVERABLE,
        OrderStatus::RECONCILED,
      ]).to_a

      # Add potentially missing custom status
      @order_statuses |= [@order_detail.order_status]

      @order_statuses.reject! { |status| status.name == OrderStatus::RECONCILED } unless @order_detail.can_reconcile?
    elsif @order_detail.order_status.root == OrderStatus.canceled
      @order_statuses = OrderStatus.canceled_statuses_for_facility(current_facility)
    else
      @order_statuses = OrderStatus.non_protected_statuses(current_facility)
    end

    unless @order_detail.unrecoverable? || can?(:mark_unrecoverable, OrderDetail)
      @order_statuses.reject! { |status| status.name == OrderStatus::UNRECOVERABLE }
    end
  end

  def edit_disabled?
    in_open_journal_or_reconciled = @order_detail.in_open_journal? || @order_detail.reconciled?

    if SettingsHelper.feature_on?(:allow_global_billing_admin_update_actual_prices)
      in_open_journal_or_reconciled || (@order_detail.awaiting_payment? && !current_user.global_billing_administrator?)
    else
      in_open_journal_or_reconciled
    end
  end

  def actual_cost_edit_disabled?
    return false unless SettingsHelper.feature_on?(:allow_global_billing_admin_update_actual_prices)

    @order_detail.awaiting_payment? && !current_user.global_billing_administrator?
  end

  def init_order_detail
    @order = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:id])
  end

  def update_params
    raw_params = params[:order_detail] || empty_params
    return raw_params if can?(:adjust_price, @order_detail)

    raw_params.except(:actual_cost, :actual_subsidy)
  end

  def authorize_mark_unrecoverable
    return if @order_detail.unrecoverable? || update_params[:order_status_id].to_s != OrderStatus.unrecoverable.id.to_s

    authorize!(:mark_unrecoverable, OrderDetail)
  end

end
