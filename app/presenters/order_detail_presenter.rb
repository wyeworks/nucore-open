# frozen_string_literal: true

class OrderDetailPresenter < SimpleDelegator

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TagHelper

  include DateHelper
  include Rails.application.routes.url_helpers

  delegate :admin_editable?, to: :reservation, prefix: true
  delegate :template_result, to: :stored_files, prefix: true

  def self.wrap(order_details)
    order_details.map { |order_detail| new(order_detail) }
  end

  def description_as_html(skip_html_escape: false)
    [bundle_name, product_name].compact.map do |description|
      skip_html_escape ? description : ERB::Util.html_escape(description)
    end.join(" &mdash; ").html_safe
  end

  def description_as_text
    name = product_name
    if bundle
      name.prepend("#{bundle_name} -- ")
    else
      name
    end.html_safe
  end

  def description_as_html_with_facility_prefix
    "#{facility.abbreviation} / #{description_as_html}".html_safe
  end

  def row_class
    reconcile_warning? ? "reconcile-warning" : ""
  end

  def show_order_detail_path
    order_order_detail_path(order, self)
  end

  def show_order_path
    facility_order_path(facility, order)
  end

  def price_group_name
    price_group&.name || estimated_price_group_name
  end

  def order_status_display_name
    order_status&.name
  end

  def display_cost
    number_to_currency(actual_cost) || number_to_currency(estimated_cost) || empty_display
  end

  def display_subsidy
    return unless has_subsidies?
    number_to_currency(actual_subsidy) || number_to_currency(estimated_subsidy) || empty_display
  end

  def actual_or_estimated_total
    actual_total || estimated_total
  end

  def display_total
    number_to_currency(actual_or_estimated_total) || empty_display
  end

  def wrapped_cost
    content_tag :span, display_cost, class: display_cost_class
  end

  def wrapped_subsidy
    content_tag :span, display_subsidy, class: display_cost_class
  end

  def wrapped_total
    content_tag :span, display_total, class: display_cost_class
  end

  def display_cost_class
    if actual_cost
      "actual_cost"
    elsif estimated_cost
      "estimated_cost"
    else
      "unassigned_cost"
    end
  end

  def actual_cost?
    actual_cost.present?
  end

  def wrapped_quantity
    build_quantity_presenter.html
  end

  def csv_quantity
    build_quantity_presenter.csv
  end

  private

  # Is a fulfilled order detail nearing the end of the 90 day reconcile period?
  # Returns true if it is 60+ days fulfilled, false otherwise
  def reconcile_warning?
    !reconciled? && fulfilled_at.present? && fulfilled_at < 60.days.ago
  end

  def build_quantity_presenter
    quantity_to_display = if product.try(:daily_booking?)
                            daily_booking_quantity
                          elsif time_data.try(:actual_duration_mins) && time_data.actual_duration_mins.to_i > 0
                            time_data.actual_duration_mins
                          elsif time_data.try(:duration_mins)
                            time_data.duration_mins
                          else
                            quantity
                          end

    QuantityPresenter.new(product, quantity_to_display)
  end

  def daily_booking_quantity
    if time_data.try(:actual_duration_days) && time_data.actual_duration_days.to_i > 0
      time_data.actual_duration_days
    elsif time_data.try(:duration_days)
      time_data.duration_days
    else
      quantity
    end
  end

  def empty_display
    "Unassigned"
  end

end
