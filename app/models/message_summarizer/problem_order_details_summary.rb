# frozen_string_literal: true

class MessageSummarizer::ProblemOrderDetailsSummary < MessageSummarizer::FacilityMessageSummary
  private

  def allowed?
    ability.can?(:show_problems, Order)
  end

  def get_count
    facility.problem_plain_order_details.count
  end

  def i18n_key
    "message_summarizer.problem_order_details"
  end

  def path
    controller.show_problems_facility_orders_path(facility)
  end
end
