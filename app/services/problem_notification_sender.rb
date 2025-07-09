# frozen_string_literal: true

class ProblemNotificationSender

  attr_reader :order_details, :current_user, :notification_groups

  def initialize(order_details, current_user, notification_groups: [])
    @order_details = order_details
    @current_user = current_user
    @notification_groups = notification_groups
  end

  def send_notifications
    return if order_details.empty?

    grouped_order_details = group_order_details_by_resolution_capability
    sent_count = 0

    notification_groups.each do |group|
      group_details = grouped_order_details[group.to_sym] || []
      next unless group_details.any?

      group_details.each do |order_detail|
        send_notification_for_order_detail(order_detail, group)
        sent_count += 1
      end
    end

    log_bulk_notification_event(sent_count)
    sent_count
  end

  def detailed_notification_count
    return { emails: 0, users: 0 } if order_details.empty?

    grouped_order_details = group_order_details_by_resolution_capability
    selected_order_details = []

    notification_groups.each do |group|
      group_details = grouped_order_details[group.to_sym] || []
      selected_order_details.concat(group_details) if group_details.any?
    end

    unique_users = selected_order_details.map(&:user).uniq

    {
      emails: selected_order_details.count,
      users: unique_users.count
    }
  end

  private

  def group_order_details_by_resolution_capability
    order_details.group_by do |order_detail|
      if OrderDetails::ProblemResolutionPolicy.new(order_detail).user_can_resolve?
        :resolvable
      else
        :non_resolvable
      end
    end
  end

  def send_notification_for_order_detail(order_detail, group)
    if group.to_sym == :resolvable
      ProblemOrderMailer.notify_user_with_resolution_option(order_detail).deliver_later
    else
      ProblemOrderMailer.notify_user(order_detail).deliver_later
    end
  end

  def log_bulk_notification_event(sent_count)
    LogEvent.log(
      order_details.first,
      :bulk_problem_notification,
      current_user,
      metadata: {
        sent_count: sent_count,
        total_order_details: order_details.count,
        notification_groups: notification_groups,
        facility_id: order_details.first.facility.id
      }
    )
  end

end
