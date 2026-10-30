# frozen_string_literal: true

class MessageSummarizer
  include Enumerable

  delegate :each, to: :visible_summaries

  cattr_accessor(:summary_classes) do
    [
      NotificationsSummary,
      OrderDetailsInDisputeSummary,
      ProblemOrderDetailsSummary,
      ProblemReservationOrderDetailsSummary,
      TrainingRequestsSummary,
    ]
  end

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
    messages? || @controller.admin_tab?
  end

  def visible_summaries
    summaries.select(&:visible?)
  end

  def summaries
    @summaries ||= summary_classes.map { |c| c.new(@controller) }
  end

  private

  def message_count
    @message_count ||= visible_summaries.sum(&:count)
  end
end
