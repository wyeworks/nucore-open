# frozen_string_literal: true

class MessageSummarizer::TrainingRequestsSummary < MessageSummarizer::FacilityMessageSummary
  private

  def allowed?
    ability.can?(:manage, TrainingRequest)
  end

  def get_count
    facility.training_requests.count
  end

  def i18n_key
    "message_summarizer.training_requests"
  end

  def in_context?
    SettingsHelper.feature_on?(:training_requests) && super
  end

  def path
    controller.facility_training_requests_path(facility)
  end
end
