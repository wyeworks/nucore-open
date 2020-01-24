# frozen_string_literal: true

class ProblemReservationResolver

  attr_reader :reservation
  delegate :order_detail, to: :reservation

  def initialize(reservation)
    @reservation = reservation
  end

  def resolve(params)
    order_detail.assign_attributes(
      problem_description_key_was: order_detail.problem_description_key,
      problem_resolved_at: Time.current,
      problem_resolved_by: params[:current_user],
    )
    reservation.assign_times_from_params(params)
    # This would have been set to the reserve_end_at by the auto expirer, but it should
    # be the actual_end_at.
    order_detail.fulfilled_at = reservation.actual_end_at
    # The changes we made above won't trigger an automatic repricing, so we need to
    # do it manually.
    order_detail.assign_price_policy
    reservation.save
  end

  def editable?
    OrderDetails::ProblemResolutionPolicy.new(order_detail).user_can_resolve?
  end

  def resolved?
    OrderDetails::ProblemResolutionPolicy.new(order_detail).user_did_resolve?
  end

end
