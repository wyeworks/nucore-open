class ReservationCreator

  attr_reader :order, :order_detail, :params, :error

  delegate :merged_order?, :instrument_only_order?, to: :status_q

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

        save_reservation_and_order_detail(session_user)

        validator = OrderPurchaseValidator.new(@order)
        raise ActiveRecord::RecordInvalid, @order_detail if validator.invalid?

        if to_be_merged
          # The purchase_order_path or cart_path will handle the backdating, but we need
          # to do this here for merged reservations.
          backdate_reservation_if_necessary(session_user)
          @success = :merged_order
        elsif @order.order_details.one?
          @success = :instrument_only_order
        else
          @success = :default
        end
      rescue ActiveRecord::RecordInvalid => e
        @error = e.message
        raise ActiveRecord::Rollback
      rescue => e
        @error = I18n.t("orders.purchase.error")
        @error += " #{e.message}" if e.message
        raise ActiveRecord::Rollback
      end
    end
  end

  def reservation
    return @reservation if @reservation
    @reservation = @order_detail.build_reservation
    @reservation.assign_attributes(reservation_create_params)
    @reservation.assign_times_from_params(reservation_create_params)
    @reservation
  end

  private

  def reservation_create_params
    params[:reservation]
      .except(:reserve_end_date, :reserve_end_hour, :reserve_end_min, :reserve_end_meridian)
      .merge(product: @order_detail.product)
  end

  def update_order_account
    if params[:order_account].present?
      account = Account.find(params[:order_account].to_i)
      if account != @order.account
        @order.invalidate
        @order.update_attributes!(account: account)
      end
    end
  end

  def backdate_reservation_if_necessary(session_user)
    facility_ability = Ability.new(session_user, @order.facility, self)
    if facility_ability.can?(:order_in_past, @order) && @reservation.reserve_end_at < Time.zone.now
      @order_detail.backdate_to_complete!(@reservation.reserve_end_at)
    end
  end

  def save_reservation_and_order_detail(session_user)
    reservation.save_as_user!(session_user)
    order_detail.assign_estimated_price(reservation.reserve_end_at)
    order_detail.save_as_user!(session_user)
  end

  def status_q
    ActiveSupport::StringInquirer.new(@success.to_s)
  end

end
