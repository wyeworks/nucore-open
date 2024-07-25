# frozen_string_literal: true

class OrderDetailBatchUpdater

  # TODO: Extracted from the OrderDetail model almost as-is and needs refactoring

  attr_accessor :facility, :msg_hash, :msg_type, :order_detail_ids, :user, :params

  # returns a hash of :notice (and/or?) :error
  # these should be shown to the user as an appropriate flash message
  #
  # Required Parameters:
  #
  # order_detail_ids: enumerable of strings or integers representing
  #                   order_details to attempt update of
  #
  # params:           a hash containing updates to attempt on the order_details
  #
  # user:             user requesting the update
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

  def self.permitted_attributes
    @permitted_attributes ||= %i(assigned_user_id order_status_id project_id)
  end

  def initialize(order_detail_ids, facility, user, params, msg_type = "orders")
    @order_detail_ids = order_detail_ids
    @facility = facility
    @user = user
    @params = params
    @msg_type = msg_type
    @msg_hash = {}
  end

  def update!
    unless order_detail_ids.present?
      msg_hash[:error] = "No #{msg_type} selected"
      return msg_hash
    end

    if order_details.none?
      msg_hash[:error] = "There was an error updating the selected #{msg_type}"
      return msg_hash
    end

    OrderDetail.transaction do
      update_order_details_from_params

      unless changes?
        msg_hash[:notice] = "No changes were required"
        return msg_hash
      end

      begin
        newly_assigned_order_details = select_newly_assigned(order_details)
        order_details.all?(&:save!)
        notify_newly_assigned_users(newly_assigned_order_details)
        msg_hash[:notice] = "The #{msg_type} were successfully updated"
      rescue
        msg_hash[:error] = "There was an error updating the selected #{msg_type}"
        raise ActiveRecord::Rollback
      end
    end

    msg_hash
  end

  private

  def changes?
    @changes.present?
  end

  def flag_change
    @changes = true
  end

  def notify_newly_assigned_users(order_details)
    return unless SettingsHelper.feature_on?(:order_assignment_notifications)
    OrderAssignmentMailer.notify_assigned_user(order_details).deliver_later
  end

  def order_details
    @order_details ||=
      facility.order_details.batch_updatable.where(id: order_detail_ids)
  end

  def order_status
    @order_status ||= OrderStatus.find(params[:order_status_id])
  end

  def select_newly_assigned(order_details)
    order_details.select do |order_detail|
      order_detail.assigned_user_id_changed? && order_detail.assigned_user_id.present?
    end
  end

  def update_order_details_from_params
    self.class.permitted_attributes.each do |attribute|
      next if params[attribute].blank?

      flag_change

      if attribute == :order_status_id
        update_all_order_status_ids
      else
        value = params[attribute] == "unassign" ? nil : params[attribute]
        update_all(attribute, value)
      end
    end
  end

  def update_all(attribute, value)
    order_details.each do |order_detail|
      order_detail.public_send("#{attribute}=", value)
    end
  end

  def update_all_order_status_ids
    order_details.each do |order_detail|
      # cancel reservation order details
      if order_status.id == OrderStatus.canceled.id && order_detail.reservation
        unless order_detail.cancel_reservation(user, order_status: order_status, admin: true)
          raise "#{msg_type} ##{order_detail} failed cancellation."
        end
      # cancel other orders or change status of any order
      else
        order_detail.change_status!(order_status)
      end
      order_detail.notify_purchaser_of_order_status
    end
  rescue => e
    msg_hash[:error] =
      "There was an error updating the selected #{msg_type}. #{e.message}"
    raise ActiveRecord::Rollback
  end

end
