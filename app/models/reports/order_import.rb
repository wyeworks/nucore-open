# frozen_string_literal: true

class Reports::OrderImport

  def initialize(order_import)
    @order_import = order_import
  end

  def description
    "Bulk Order Import Results"
  end

  def filename
    "bulk_import_result.csv"
  end

  def text_content
    case
    when @order_import.result.blank?
      I18n.t("reports.order_import.blank")
    when @order_import.result.failed?
      I18n.t(failure_message_key, **@order_import.result.to_h)
    else
      I18n.t("reports.order_import.success", **@order_import.result.to_h)
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
