# frozen_string_literal: true

class Reports::OrderImport

  def initialize(order_import:, successes:, failures:)
    @order_import = order_import
    @result = ::OrderImport::Result.new(successes:, failures:)
  end

  def description
    "Bulk Order Import Results"
  end

  def filename
    "bulk_import_result.csv"
  end

  def text_content
    case
    when @result.blank?
      I18n.t("reports.order_import.blank")
    when @result.failed?
      I18n.t(failure_message_key, **@result.to_h)
    else
      I18n.t("reports.order_import.success", **@result.to_h)
    end
  end

  def to_csv
    @order_import.error_file_content
  end

  def has_attachment?
    @order_import.error_file_present?
  end

  private

  def failure_message_key
    if @order_import.fail_on_error?
      "reports.order_import.fail_immediately"
    else
      "reports.order_import.fail_continue_on_error"
    end
  end

end
