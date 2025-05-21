# frozen_string_literal: true

class OrderDetailNoticePresenter < DelegateClass(OrderDetail)

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::OutputSafetyHelper

  def statuses
    return [] if canceled?
    statuses = []

    statuses << Notice.new(:in_review) if in_review?
    statuses << Notice.new(:in_dispute) if in_dispute? && !global_admin_must_resolve?
    statuses << Notice.new(:global_admin_must_resolve) if in_dispute? && global_admin_must_resolve?
    statuses << Notice.new(:missing_form) if missing_form? && !problem?
    statuses << Notice.new(:can_reconcile) if can_reconcile_journaled?
    statuses << Notice.new(:in_open_journal) if in_open_journal?
    statuses << Notice.new(:ready_for_statement) if ready_for_statement?
    statuses << Notice.new(:ready_for_journal) if ready_for_journal? && SettingsHelper.feature_on?(:ready_for_journal_notice)
    statuses << Notice.new(:awaiting_payment) if awaiting_payment?

    statuses
  end

  def warnings
    warnings = []

    problem_description_key.then do |problem_key|
      warnings << Notice.new(problem_key, :warning) if problem_key.present? && problem?
    end

    warnings
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
        status: "label-info",
        warning: "label-important",
      }.fetch(@severity)
    end

  end

end
