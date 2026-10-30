# frozen_string_literal: true

class MessageSummarizer::FacilityMessageSummary < MessageSummarizer::MessageSummary
  private

  def in_context?
    facility && controller.admin_tab?
  end

  def facility
    controller.current_facility
  end
end
