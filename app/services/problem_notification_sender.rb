# frozen_string_literal: true

class ProblemNotificationSender

  attr_reader :order_details, :current_user, :notification_groups

  def initialize(order_details, current_user, notification_groups: [])
    @order_details = order_details
    @current_user = current_user
    @notification_groups = notification_groups.map(&:to_sym)
  end

  def send_notifications
    selected_order_details.each { |group, order_detail| deliver(group, order_detail) }
    log_bulk_notification_event(notified_order_details)
    selected_order_details.count
  end

  def detailed_notification_count
    {
      emails: selected_order_details.count,
      users: notified_order_details.map(&:user).uniq.count
    }
  end

  private

  def selected_order_details
    @selected_order_details ||=
      order_details.filter_map do |order_detail|
        group = resolution_group(order_detail)
        [group, order_detail] if notification_groups.include?(group)
      end
  end

  def notified_order_details
    selected_order_details.map { |_group, order_detail| order_detail }
  end

  def resolution_group(order_detail)
    if OrderDetails::ProblemResolutionPolicy.new(order_detail).user_can_resolve?
      :resolvable
    else
      :non_resolvable
    end
  end

  def deliver(group, order_detail)
    if group == :resolvable
      ProblemOrderMailer.notify_user_with_resolution_option(order_detail).deliver_later
    else
      ProblemOrderMailer.notify_user(order_detail).deliver_later
    end
  end

  def log_bulk_notification_event(notified)
    notified.group_by(&:user).each do |user, details|
      LogEvent.log(
        user,
        :bulk_problem_notification,
        current_user,
        metadata: {
          order_detail_ids: details.map(&:id).join(", ")
        }
      )
    end
  end

end
