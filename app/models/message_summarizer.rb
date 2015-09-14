class MessageSummarizer
  include Enumerable

  delegate :each, to: :message_summaries

  def initialize(controller)
    @controller = controller
  end

  def messages?
    message_count > 0
  end

  def tab_label
    I18n.t("message_summarizer.heading", count: message_count)
  end

  def visible_tab?
    manager_context? || notifications.any?
  end

  private

  def manager_context?
    @controller.admin_tab?
  end

  def message_count
    @message_count ||= message_summaries.sum(&:count)
  end

  def notifications
    @notifications ||= NotificationsSummary.new(@controller)
  end

  def order_details_in_dispute
    @order_details_in_dispute ||= OrderDetailsInDisputeSummary.new(@controller)
  end

  def problem_order_details
    @problem_order_details ||= ProblemOrderDetailsSummary.new(@controller)
  end

  def problem_reservation_order_details
    @problem_reservation_order_details ||=
      ProblemReservationOrderDetailsSummary.new(@controller)
  end

  def training_requests
    @training_requests ||= TrainingRequestsSummary.new(@controller)
  end

  def message_summaries
    [
      notifications,
      order_details_in_dispute,
      problem_order_details,
      problem_reservation_order_details,
      training_requests,
    ].select(&:any?)
  end
end
