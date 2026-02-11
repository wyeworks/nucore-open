# frozen_string_literal: true

class OrderDetailNoticePresenter < DelegateClass(OrderDetail)
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::OutputSafetyHelper

  def notices_service
    @notices_service ||= OrderDetails::NoticesService.new(self)
  end

  def statuses
    values = if SettingsHelper.feature_on?(:stored_order_notices)
               notice_keys
             else
               notices_service.notices
             end
    values.map { |s| Notice.new(s) }
  end

  def warnings
    if problem?
      problem_key = if SettingsHelper.feature_on?(:stored_order_notices)
                      problem_description_key
                    else
                      notices_service.problems.first
                    end
      [Notice.new(problem_key || :problem_out_of_sync, :warning)]
    else
      []
    end
  end

  def notices
    statuses + warnings
  end

  # Filter to only status or warnings by passing `only: :status` or `only: :warning`
  def badges_to_html(only: [:status, :warning])
    filtered = notices.select { |notice| Array(only).include?(notice.severity) }

    safe_join(filtered.map(&:badge_to_html))
  end

  def badges_to_text(only: [:status, :warning])
    filtered = notices.select { |notice| Array(only).include?(notice.severity) }

    filtered.map(&:badge_text).join("+").presence
  end

  def alerts_to_html
    blocks = [
      build_alert(warnings, "error"),
      build_alert(statuses, "info"),
    ].compact

    safe_join(blocks)
  end

  private

  def build_alert(notices, severity_class)
    return if notices.none?

    text = safe_join(notices.map(&:alert_text), content_tag(:br))
    content_tag(:div, text, class: ["alert", "alert-#{severity_class}"])
  end

  # Not meant to be used outside the presenter class
  class Notice

    include ActionView::Helpers::TagHelper
    include TextHelpers::Translation

    # this is just to enable use of `text` from the TextHelpers::Translation
    # module
    def translation_scope
      "order_details.notices"
    end

    attr_reader :severity

    def initialize(key, severity = :status)
      @key = key
      @severity = severity
    end

    def badge_text
      text("#{@key}.badge")
    end

    def alert_text
      text("#{@key}.alert")
    end

    def badge_to_html
      content_tag(:span, badge_text, class: ["label", label_class])
    end

    private

    def label_class
      {
        status: "label-default",
        warning: "label-danger",
      }.fetch(@severity)
    end

  end

end
