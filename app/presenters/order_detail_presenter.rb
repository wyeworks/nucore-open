# frozen_string_literal: true

class OrderDetailPresenter < SimpleDelegator

  include ActionView::Helpers::NumberHelper
  include DateHelper
  include Rails.application.routes.url_helpers
  include PriceDisplayment

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

  def account_display_description
    account_description
  end

  private

  # Is a fulfilled order detail nearing the end of the 90 day reconcile period?
  # Returns true if it is 60+ days fulfilled, false otherwise
  def reconcile_warning?
    !reconciled? && fulfilled_at.present? && fulfilled_at < 60.days.ago
  end

end
