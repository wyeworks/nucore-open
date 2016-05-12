class OrderDetailBatchUpdater

  attr_accessor :current_facility, :msg_hash, :msg_type, :order_detail_ids, :session_user, :update_params

  # returns a hash of :notice (and/or?) :error
  # these should be shown to the user as an appropriate flash message
  #
  # Required Parameters:
  #
  # order_detail_ids: enumerable of strings or integers representing
  #                   order_details to attempt update of
  #
  # update_params:    a hash containing updates to attempt on the order_details
  #
  # session_user:     user requesting the update
  #
  # Acceptable Updates:
  #   key                     value
  #   ---------------------------------------------------------------------
  #   :assigned_user_id       integer or string: id of a User
  #                                              they should be assigned to
  #
  #                                               OR
  #
  #                                              'unassign'
  #                                              (to unassign current user)
  #
  #
  #   :order_status_id        integer or string: id of an OrderStatus
  #                                              they should be set to
  #
  #
  # Optional Parameters:
  #
  # msg_type:         a plural string used in error/success messages to indicate
  #                   type of records,
  #                   (since this class method is also used to update
  #                   order_details associated with reservations)
  #                   defaults to 'orders'

  def initialize(order_detail_ids, current_facility, session_user, update_params, msg_type = "orders")
    @order_detail_ids = order_detail_ids
    @current_facility = current_facility
    @session_user = session_user
    @update_params = update_params
    @msg_type = msg_type
    @msg_hash = {}
  end

  def update!
    unless order_detail_ids.present?
      msg_hash[:error] = "No #{msg_type} selected"
      return msg_hash
    end

    order_details = OrderDetail.find(order_detail_ids)

    if order_details.any? { |od| od.product.facility_id != current_facility.id || !(od.state.include?("inprocess") || od.state.include?("new")) }
      msg_hash[:error] = "There was an error updating the selected #{msg_type}"
      return msg_hash
    end

    changes = false
    if update_params[:assigned_user_id] && update_params[:assigned_user_id].length > 0
      changes = true
      order_details.each { |od| od.assigned_user_id = (update_params[:assigned_user_id] == "unassign" ? nil : update_params[:assigned_user_id]) }
    end

    OrderDetail.transaction do
      if update_params[:order_status_id] && update_params[:order_status_id].length > 0
        changes = true
        begin
          os = OrderStatus.find(update_params[:order_status_id])
          order_details.each do |od|
            # cancel reservation order details
            if os.id == OrderStatus.canceled.first.id && od.reservation
              raise "#{msg_type} ##{od} failed cancellation." unless od.cancel_reservation(session_user, os, true)
            # cancel other orders or change status of any order
            else
              od.change_status!(os)
            end
          end
        rescue => e
          msg_hash[:error] = "There was an error updating the selected #{msg_type}.  #{e.message}"
          raise ActiveRecord::Rollback
        end
      end
      unless changes
        msg_hash[:notice] = "No changes were required"
        return msg_hash
      end
      begin
        order_details.all?(&:save!)
        msg_hash[:notice] = "The #{msg_type} were successfully updated"
      rescue
        msg_hash[:error] = "There was an error updating the selected #{msg_type}"
        raise ActiveRecord::Rollback
      end
    end

    msg_hash
  end

end
