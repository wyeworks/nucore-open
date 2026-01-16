# frozen_string_literal: true

class OrdersController < ApplicationController

  customer_tab  :all

  before_action :check_acting_as,          except: [:cart, :cart_order_details_count, :add, :choose_account, :show, :remove, :purchase, :update_or_purchase, :receipt, :update]
  before_action :init_order,               except: [:cart, :cart_order_details_count, :index, :receipt]
  before_action :protect_purchased_orders, except: [:cart, :cart_order_details_count, :receipt, :index]
  before_action :load_statuses, only: [:show, :update, :purchase, :update_or_purchase]

  # Using fetch instead of jQuery/XHR, and the only thing this action does is update the cart count
  skip_after_action :verify_same_origin_request, only: [:cart_order_details_count]

  def self.permitted_params
    @permitted_params ||= []
  end

  def self.permitted_acting_as_params
    @permitted_acting_as_params ||= [:project_id]
  end

  def initialize
    @active_tab = "orders"
    super
  end

  def init_order
    @order = Order.find(params[:id])
  end

  def protect_purchased_orders
    if @order.state == "purchased"
      redirect_to(receipt_order_path(@order)) && return
    end
  end

  # GET /orders/cart
  def cart
    @order = acting_user.cart(session_user)
    redirect_to(order_path(@order)) && return
  end

  def cart_order_details_count
    respond_to do |format|
      format.js do
        order_details_count = acting_user.cart(session_user).order_details.count

        render json: { data: { count: order_details_count } }
      end
    end
  end

  # GET /orders/:id
  def show
    facility_ability = Ability.new(session_user, @order.facility, self)
    @order.being_purchased_by_admin = facility_ability.can?(:act_as, @order.facility)
    @order.validate_order! if @order.new?

    return unless @order.order_details.any? && !@order.has_valid_payment?

    @order.errors.add(:base, invalid_for_orderer_message)

    flash.now[:error] = "There are errors in your order:<br>#{@order.errors.full_messages.join('<br>')}".html_safe
  end

  # PUT /orders/:id/clear
  def clear
    @order.clear!
    redirect_to(order_path(@order)) && return
  end

  # GET /orders/2/add/
  # PUT /orders/2/add/
  def add
    ## get items to add from the form post or from the session
    ods_from_params = (params[:order].presence && params[:order][:order_details].presence) || []
    items = ods_from_params.presence || session[:add_to_cart].presence || []
    session[:add_to_cart] = nil

    # ignore ods w/ empty or 0 quantities
    items = items.compact.map { |i| i.permit(:product_id, :quantity) }.select { |od| od[:quantity].to_i > 0 }
    return redirect_back(fallback_location: cart_path, notice: "Please add at least one quantity to order something") unless items.size > 0

    first_product = Product.find(items.first[:product_id])
    facility_ability = Ability.new(session_user, first_product.facility, self)

    # if acting_as, make sure the session user can place orders for the facility
    if acting_as? && facility_ability.cannot?(:act_as, first_product.facility)
      flash[:error] = "You are not authorized to place an order on behalf of another user for the facility #{current_facility.try(:name)}."
      redirect_to(order_path(@order)) && return
    end

    ## handle a single instrument reservation
    if items.size == 1 && (quantity = items.first[:quantity].to_i) == 1 # only one od w/ quantity of 1
      if first_product.respond_to?(:reservations) # and product is reservable

        # make a new cart w/ instrument (unless this order is empty.. then use that one)
        @order = acting_user.cart(session_user, @order.order_details.empty?)

        # wipe out stale account info in temp cart to avoid account related errors
        @order.account = nil
        @order.account_id = nil

        @order.add(first_product, 1)

        # bypass cart kicking user over to new reservation screen
        return redirect_to new_order_order_detail_reservation_path(@order.id, @order.order_details.first)
      end
    end

    ## make sure the order has an account
    if @order.account.nil?
      ## add auto_assign back here if needed

      ## save the state to the session and redirect
      session[:add_to_cart] = items
      redirect_to(choose_account_order_path(@order)) && return
    end

    ## process each item
    @order.transaction do
      items.each do |item|
        @product = Product.find(item[:product_id])
        begin
          @order.add(@product, item[:quantity])
          @order.invalidate! ## this is because we just added an order_detail
        rescue NUCore::MixedFacilityCart
          @order.errors.add(:base, "You can not add a product from another facility; please clear your cart or place a separate order.")
        rescue NUCore::MixedBillingMode
          @order.errors.add(:base, "#{@product.name} cannot be added to your cart because it's billing mode does not match the current products in the cart; please clear your cart or place a separate order.")
        rescue => e
          if !@order.has_valid_payment?
            @order.errors.add(:base, invalid_for_orderer_message)
          else
            @order.errors.add(:base, "An error was encountered while adding the product #{@product}.")
          end
          Rails.logger.error(e.message)
          Rails.logger.error(e.backtrace.join("\n"))
        end
      end

      if @order.errors.any?
        flash[:error] = "There were errors adding to your cart:<br>#{@order.errors.full_messages.join('<br>')}".html_safe
        raise ActiveRecord::Rollback
      end
    end

    redirect_to order_path(@order)
  end

  # PUT /orders/:id/remove/:order_detail_id
  def remove
    order_detail = @order.order_details.find(params[:order_detail_id])

    # remove bundles
    if order_detail.group_id
      order_details = @order.order_details.where(group_id: order_detail.group_id)
      OrderDetail.transaction do
        if order_details.all?(&:destroy)
          flash[:notice] = "The bundle has been removed."
        else
          flash[:error] = "An error was encountered while removing the bundle."
        end
      end
    # remove single products
    else
      if order_detail.destroy
        flash[:notice] = "The product has been removed."
      else
        flash[:error] = "An error was encountered while removing the product."
      end
    end

    redirect_to params[:redirect_to].presence || order_path(@order)

    # clear out account on the order if its now empty
    if !@order.destroyed? && @order.order_details.reload.empty?
      @order.account_id = nil
      @order.save!
    end
  end

  # GET  /orders/:id/choose_account
  # POST /orders/:id/choose_account
  def choose_account
    @product = if session[:add_to_cart].blank?
              @order.order_details[0].try(:product)
            else
              Product.find(session[:add_to_cart].first[:product_id])
            end
    # For nonbillable products, we don't ask the user to choose an account
    # POST requests are sent from the form on the choose_account page,
    # so we need to assign the account selected by the user to the order
    account = if @product.blank?
                nil
              elsif @product.nonbillable_mode?
                NonbillableAccount.singleton_instance
              elsif request.post?
                Account.where(id: params[:account_id]).first
              end
    add_account_result = add_account_to_order(account) if account.present?

    if @product.blank?
      redirect_to(cart_path)
    elsif add_account_result && add_account_result[:success]
      redirect_to add_account_result[:redirect_path]
    else
      flash.now[:error] = add_account_result[:error_message] if add_account_result && add_account_result[:error_message]
      flash.now[:error] = I18n.t("controllers.orders.choose_account.missing_account") if account.blank? && request.post?
      @accounts = AvailableAccountsFinder.new(acting_user, @product.facility).accounts
      @errors   = {}
      details   = @order.order_details
      @accounts.each do |account|
        if session[:add_to_cart] &&
           (ods = session[:add_to_cart].presence) &&
           (product_id = ods.first[:product_id])
          error = account.validate_against_product(Product.find(product_id), acting_user)
          @errors[account.id] = error if error
        end
        next if @errors[account.id]
        details.each do |od|
          error = account.validate_against_product(od.product, acting_user)
          @errors[account.id] = error if error
        end
      end
    end
  end

  def add_account
    flash.now[:notice] = "This page is still in development; please add an account administratively"
  end

  # PUT /orders/:id/update_or_purchase (submission from a cart)
  def update_or_purchase
    # When returning from an external service, we may be called with a get; in that
    # case, we should just redirect to the show path
    redirect_to(action: :show) && return if request.get?

    # if update button was clicked
    if params[:commit] == "Update"
      update
    else
      purchase
    end
  end

  # PUT /orders/:id/update
  def update
    @order.transaction do
      @order.assign_attributes(order_params)

      if OrderDetailUpdater.new(@order, order_update_params).update
        # Must render instead of redirect to maintain "more options" state when
        # ordering on behalf of
        flash.now[:notice] = "Cart has been updated"
      else
        logger.debug "errors #{@order.errors.full_messages}"
        flash.now[:error] = @order.errors.full_messages.join("<br/>").html_safe
      end
      render :show
    end
  end

  # PUT /orders/:id/purchase
  def purchase
    @order.being_purchased_by_admin = facility_ability.can?(:act_as, @order.facility)

    order_purchaser.backdate_to = build_order_date if ordering_on_behalf_with_date_params?

    @order.transaction do
      @order.assign_attributes(order_params)
      order_purchaser.purchase!
    end

    if order_purchaser.success?
      should_show_admin_hold_warning = @order.order_details.map(&:reservation).compact.any?(&:conflicting_admin_reservation)
      flash[:error] = I18n.t("controllers.reservations.create.admin_hold_warning") if should_show_admin_hold_warning

      if single_reservation? && !acting_as?
        flash[:notice] = I18n.t("controllers.orders.purchase.reservation.success")
        if can_switch_instrument_on?
          redirect_to switch_instrument_path
        else
          redirect_to reservations_path
        end
      else
        redirect_to receipt_order_path(@order)
      end
    else
      flash.now[:error] = order_purchaser.errors.join("<br/>").html_safe if order_purchaser.errors.present?
      render :show
    end
  rescue => e
    flash.now[:error] = I18n.t("orders.purchase.error", message: e.message).html_safe
    @order.reload.invalidate!
    render :show
  end

  # GET /orders/1/receipt
  def receipt
    @order = Order.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @order.purchased?

    @order_details = @order.order_details.select { |od| od.can_be_viewed_by?(acting_user) }
    raise ActiveRecord::RecordNotFound if @order_details.empty?

    @accounts = @order_details.collect(&:account).uniq
  end

  # GET /orders
  # all my orders
  def index
    # new or in process
    @order_details = session_user.order_details.item_and_service_orders
    @available_statuses = %w(pending all)
    case params[:status]
    when "pending"
      @order_details = @order_details.new_or_inprocess
    when "all"
      @order_details = @order_details.purchased
    else
      redirect_to orders_status_path(status: "pending")
      return
    end
    @order_details = @order_details. order("order_details.created_at DESC").paginate(page: params[:page])
  end

  private

  def add_account_to_order(account)
    if account
      success = true
      @order.transaction do
        begin
          @order.invalidate
          @order.update!(account_id: account.id)
        rescue ActiveRecord::ActiveRecordError => e
          success = false
          raise ActiveRecord::Rollback
        end
      end
    end

    result = { success: success, redirect_path: nil, error_message: nil }
    if success
      result[:redirect_path] = if session[:add_to_cart].nil?
        cart_path
      else
        add_order_path(@order)
      end
    else
      result[:error_message] = if account.nil?
        "Please select a payment method."
      else
        "An error was encountered while selecting a payment method."
      end
    end
    result
  end

  def build_order_date
    if params[:order_date].present?
      parse_usa_date(params[:order_date])
    end
  end

  def can_switch_instrument_on?
    first_order_detail.reservation.can_switch_instrument_on?
  end

  def facility_ability
    @facility_ability ||= Ability.new(session_user, @order.facility, self)
  end

  def first_order_detail
    @first_order_detail ||= @order.order_details.first
  end

  def load_statuses
    @order_statuses = OrderStatus.non_protected_statuses(@order.facility)
  end

  def order_params
    return ActionController::Parameters.new if params[:order].blank?
    if acting_as?
      params[:order].permit(*(self.class.permitted_params + self.class.permitted_acting_as_params))
    else
      params[:order].permit(*self.class.permitted_params)
    end
  end

  def order_purchaser
    @order_purchaser ||= OrderPurchaser.new(
      acting_as: acting_as?,
      order: @order,
      order_in_past: facility_ability.can?(:order_in_past, @order),
      params: params,
      user: session_user,
    )
  end

  def order_update_params
    @order_update_params ||= OrderDetailUpdateParamHashExtractor.new(params).to_h
  end

  def ordering_on_behalf_with_date_params?
    params[:order_date].present? && acting_as?
  end

  def single_reservation?
    @order.order_details.size == 1 &&
      @order.order_details.first.product.is_a?(Instrument) &&
      !@order.order_details.first.bundled?
  end

  def switch_instrument_path
    order_order_detail_reservation_switch_instrument_path(
      @order,
      first_order_detail,
      first_order_detail.reservation,
      switch: "on",
      redirect_to: reservations_path,
    )
  end

  def invalid_for_orderer_message
    text("models.order.account_invalid_for_orderer",
      clear_cart_link: clear_order_path(@order),
      change_payment_source_link: choose_account_order_path(@order))
  end

end
