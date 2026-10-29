# frozen_string_literal: true

class MessageSummarizer::ProblemReservationOrderDetailsSummary < MessageSummarizer::FacilityMessageSummary
  private

  def allowed?
    ability.can?(:show_problems, Reservation)
  end

  def get_count
    facility.problem_reservation_order_details.count
  end

  def i18n_key
    "message_summarizer.problem_reservation_order_details"
  end

  def path
    controller.show_problems_facility_reservations_path(facility)
  end
end
