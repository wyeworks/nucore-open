# frozen_string_literal: true

module JournalsHelper
  def journal_status_options(_journal)
    [nil, 'succeeded', 'succeeded_errors', 'failed'].map do |status|
      if status.present?
        [t("facility_journals.status_options.#{status}"), status]
      else
        [t("facility_journals.status_options.blank"), nil]
      end
    end
  end
end
