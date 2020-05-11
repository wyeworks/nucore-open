# frozen_string_literal: true

class OrderDetails::ParamUpdater

  def self.permitted_attributes
    @permitted_attributes ||=
      [
        :account_id,
        :assigned_user_id,
        :resolve_dispute,
        :dispute_resolved_reason,
        :quantity,
        :note,
        :price_change_reason,
        :editing_time_data,
        :reconciled_note,
        :reference_id,
        reservation: [
          :reserve_start_date,
          :reserve_start_hour,
          :reserve_start_min,
          :reserve_start_meridian,
          :duration_mins,
          :actual_start_date,
          :actual_start_hour,
          :actual_start_min,
          :actual_start_meridian,
          :actual_duration_mins,
        ],
      ]
  end

  def initialize(order_detail, options = {})
    @order_detail = order_detail
    @editing_user = options[:user]
    @options = options
  end

  def assign_attributes(params)
    params = params.dup
    params.delete(:quantity) unless params[:quantity].to_s =~ /\A\d+\z/

    assign_self_and_reservation_attributes(permitted_params(params))
    # As of Rails 5.2.4, if nothing changes on the association (e.g. submitting the
    # form with no changes on a reservation/occupancy missing end_at), the validations
    # no longer run on the associations.
    @order_detail.time_data.force_dirty!

    # this will overwrite the prices, so if we got cost/subsidy as parameters,
    # we need to use them instead
    assign_policy_and_prices
    @order_detail.assign_attributes(cost_params(params))

    @order_detail
  end

  def update_attributes(params)
    params = params.try(:dup) || {}

    # Assign all the attributes first, and then update the order status.
    # We need to go through update_order_status! so we can cancel the reservation
    # when necessary
    order_status_id = params.delete :order_status_id

    @order_detail.manual_fulfilled_at = params[:fulfilled_at]

    assign_attributes(params)

    @order_detail.manually_priced! # don't auto-reassign price

    @order_detail.transaction do
      assign_price_changed_by_user
      @order_detail.reservation.save_as_user(@editing_user) if @order_detail.reservation
      if order_status_id && order_status_id.to_i != @order_detail.order_status_id
        change_order_status(order_status_id, @options[:cancel_fee]) || raise(ActiveRecord::Rollback)
      else
        @order_detail.save_as_user(@editing_user) || raise(ActiveRecord::Rollback)
      end
    end
    merge_reservation_errors if @order_detail.reservation.present?
    trigger_notifications if @order_detail.errors.none?

    @order_detail.errors.none?
  end

  def trigger_notifications
    OrderDetails::DisputeResolvedNotifier.new(@order_detail,current_user: @editing_user).notify
    OrderDetails::AssignmentNotifier.new(@order_detail).notify
  end

  private

  def assign_price_changed_by_user
    if @order_detail.actual_costs_match_calculated?
      @order_detail.price_changed_by_user = nil
    elsif %w[actual_cost actual_subsidy price_change_reason].any? { |a| @order_detail.changed.include?(a) }
      @order_detail.price_changed_by_user = @editing_user
      LogEvent.log(@order_detail, :price_change, @editing_user)
    end
  end

  def cost_params(params)
    params.slice(:actual_cost, :actual_subsidy).permit!
  end

  def permitted_params(params)
    QuietStrongParams.with_dropped_params do
      params.permit(*self.class.permitted_attributes)
    end
  end

  def assign_self_and_reservation_attributes(params)
    reservation_attrs = params.delete :reservation
    @order_detail.assign_attributes(params)

    if @order_detail.time_data.is_a?(Reservation)
      @order_detail.reservation.assign_times_from_params reservation_attrs if reservation_attrs
    end
  end

  def assign_policy_and_prices
    @order_detail.assign_price_policy if @order_detail.complete?
    @order_detail.assign_estimated_price unless @order_detail.price_policy && @order_detail.actual_cost
  end

  def change_order_status(new_order_status_id, apply_cancel_fee)
    new_order_status = OrderStatus.find(new_order_status_id)
    @order_detail.update_order_status!(@editing_user, new_order_status, admin: true, apply_cancel_fee: apply_cancel_fee)
    @order_detail.notify_purchaser_of_order_status
    true
  rescue => e
    @order_detail.errors.add(:base, :changing_status)
  end

  # Occupancies use accepts_nested_attributes which handles this.
  def merge_reservation_errors
    @order_detail.reservation.errors.each do |field, message|
      field = Reservation.human_attribute_name(field) if field != :base
      @order_detail.errors.add(field, message)
    end
  end

end
