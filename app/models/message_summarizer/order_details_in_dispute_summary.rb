# frozen_string_literal: true

class MessageSummarizer::OrderDetailsInDisputeSummary < MessageSummarizer::FacilityMessageSummary
  private

  def allowed?
    ability.can?(:disputed_orders, Facility)
  end

  def get_count
    facility.order_details_in_dispute.count
  end

  def i18n_key
    "message_summarizer.order_details_in_dispute"
  end

  def path
    controller.facility_disputed_orders_path(facility)
  end
end
