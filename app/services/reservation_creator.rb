# frozen_string_literal: true

class ReservationCreator

  attr_reader :order, :order_detail, :params, :error

  delegate :merged_order?, :instrument_only_order?, to: :status_q
  delegate :product, to: :order_detail

  def initialize(order, order_detail, params)
    @order = order
    @order_detail = order_detail
    @params = params
  end

  def save(session_user)
    if !@order_detail.bundled? && params[:order_account].blank?
      @error = I18n.t("controllers.reservations.create.no_selection")
      return false
    end

    Reservation.transaction do
      begin
        update_order_account

        # merge state can change after call to #save! due to OrderDetailObserver#before_save
        to_be_merged = @order_detail.order.to_be_merged?

        raise ActiveRecord::RecordInvalid, @order_detail unless reservation_and_order_valid?(session_user)

        validator = OrderPurchaseValidator.new(@order_detail)
        raise OrderPurchaseValidatorError, @order_detail if validator.invalid?

        save_reservation_and_order_detail(session_user)

        if to_be_merged
          # The purchase_order_path or cart_path will handle the backdating, but we need
          # to do this here for merged reservations.
          backdate_reservation_if_necessary(session_user)

          purchase_original_cross_core_order

          @success = :merged_order
        elsif @order.order_details.where(parent_order_detail_id: nil).one?
          @success = :instrument_only_order
        else
          @success = :default
        end
      rescue OrderPurchaseValidatorError => e
        @error = e.message
        raise ActiveRecord::Rollback
      rescue ActiveRecord::RecordInvalid => e
        raise ActiveRecord::Rollback
      rescue StandardError => e
        @error = I18n.t("orders.purchase.error", message: e.message).html_safe
        raise ActiveRecord::Rollback
      end
    end
  end

  def reservation
    return @reservation if defined?(@reservation)
    @reservation = @order_detail.build_reservation
    @reservation.assign_attributes(reservation_create_params)
    @reservation.assign_times_from_params(reservation_create_params)
    @reservation
  end

  private

  def reservation_create_params
    duration_field = if order_detail.product.daily_booking?
                       :duration_days
                     else
                       :duration_mins
                     end

    params
      .require(:reservation)
      .permit(
        :reserve_start_date,
        :reserve_start_hour,
        :reserve_start_min,
        :reserve_start_meridian,
        :note,
        :reference_id,
        :project_id,
        duration_field,
      ).merge(
        product:,
      ).tap do |reservation_params|
        if product.start_time_disabled?
          reservation_params.merge!(
            reserve_start_hour: 0,
            reserve_start_min: 0,
            reserve_start_meridian: "AM"
          )
        end
      end
  end

  def accessory_params
    return {} unless SettingsHelper.feature_on?(:add_accessories_before_reservation_starts)

    permitted_params = {}
    @order_detail.product.accessories.each do |accessory|
      permitted_params[accessory.id.to_s] = [:enabled, :quantity]
    end

    params.permit(accessories: permitted_params)[:accessories] || {}
  end

  def update_order_account
    return if params[:order_account].blank?

    account = Account.find(params[:order_account].to_i)
    # If the account has changed, we need to re-do validations on the order. We're
    # only saving the changes if the reservation is part of a cart. Otherwise, we
    # just modify the object in-memory for redisplay.
    if account != @order.account
      @order.invalidate if @order.persisted?
      @order.account = account
      @order_detail.account = account if @order_detail
      @order.save! if @order.persisted?
    end
  end

  def backdate_reservation_if_necessary(session_user)
    facility_ability = Ability.new(session_user, @order.facility, self)
    @order_detail.backdate_to_complete!(@reservation.reserve_end_at) if facility_ability.can?(:order_in_past, @order) && @reservation.reserve_end_at < Time.zone.now
  end

  def reservation_and_order_valid?(session_user)
    reservation.valid_as_user?(session_user) && order_detail.valid_as_user?(session_user)
  end

  def save_reservation_and_order_detail(session_user)
    reservation.save_as_user!(session_user)
    order_detail.assign_estimated_price(reservation.reserve_end_at)
    order_detail.save_as_user!(session_user)

    process_accessories if SettingsHelper.feature_on?(:add_accessories_before_reservation_starts)
  end

  def status_q
    ActiveSupport::StringInquirer.new(@success.to_s)
  end

  def purchase_original_cross_core_order
    original_order = Order.find(@order.merge_with_order_id)

    if original_order.order_details.one? && original_order.cross_core_project.present?
      order_purchaser = OrderPurchaser.new(
        order: original_order,
        acting_as: original_order.user,
        order_in_past: nil,
        params: ActionController::Parameters.new({}),
        user: original_order.created_by
      )
      order_purchaser.purchase_cross_core!
    end
  end

  def process_accessories
    return if accessory_params.empty?

    accessorizer = Accessories::Accessorizer.new(@order_detail)
    accessorizer.update_accessorizer_attributes(accessory_params)
  end

end
