# frozen_string_literal: true

class MoveToProblemQueue

  def self.move!(order_detail, force: false, user: nil, cause:)
    new(order_detail, force: force, user: user, cause: cause).move!
  end

  def initialize(order_detail, force: false, user: nil, cause:)
    @order_detail = order_detail
    @force = force
    @user = user
    @cause = cause
  end

  def move!
    # Some scopes may accidentally try send already-complete orders to the queue.
    # This protects against sending duplicate emails to things already in the queue.
    return unless @order_detail.pending?

    @order_detail.time_data.force_completion = @force
    @order_detail.complete!
    LogEvent.log(@order_detail, :problem_queue, @user, metadata: {cause: @cause})
    # TODO: Can probably remove this at some point, but it's a safety check for now
    raise "Trying to move Order ##{@order_detail} to problem queue, but it's not a problem" unless @order_detail.problem?

    if OrderDetails::ProblemResolutionPolicy.new(@order_detail).user_can_resolve?
      ProblemOrderMailer.notify_user_with_resolution_option(@order_detail).deliver_later
    else
      ProblemOrderMailer.notify_user(@order_detail).deliver_later
    end
  end

end
