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

  def description_as_html
    [bundle, product].compact.map do |description|
      ERB::Util.html_escape(description)
    end.join(" &mdash; ").html_safe
  end

  def description_as_text
    name = product.to_s
    if bundle
      name.prepend("#{bundle} -- ")
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

  def survey_url
    survey_completed? ? external_service_receiver.show_url : ""
  end

  private

  def format_as_currency(value)
    value.present? ? number_to_currency(value) : ""
  end

  # Is a fulfilled order detail nearing the end of the 90 day reconcile period?
  # Returns true if it is 60+ days fulfilled, false otherwise
  def reconcile_warning?
    !reconciled? && fulfilled_at.present? && fulfilled_at < 60.days.ago
  end

end
