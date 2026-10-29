# frozen_string_literal: true

module SecureRooms
  class ProblemOccupancyMessageSummary < MessageSummarizer::FacilityMessageSummary
    private

    def allowed?
      ability.can?(:show_problems, Occupancy)
    end

    def get_count
      facility.complete_problem_order_details.joins(:occupancy).count
    end

    def i18n_key
      "message_summarizer.problem_occupancies"
    end

    def path
      controller.show_problems_facility_occupancies_path(facility)
    end
  end
end
