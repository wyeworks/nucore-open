# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include DateHelper
  include TranslationHelper

  def app_name
    t :app_name
    #NUCore.app_name
  end

  def html_title(title=nil)
    full_title = title.blank? ? "" : "#{title} - "
    (full_title + app_name).html_safe
  end

  def order_detail_description(order_detail) # TODO: deprecate in favor of "_as_(html|text)" methods
    order_detail_description_as_html(order_detail)
  end

  def order_detail_description_as_html(order_detail)
    name = ERB::Util.html_escape(order_detail.product)
    if order_detail.bundle
      name.prepend(ERB::Util.html_escape(order_detail.bundle) + " &mdash; ".html_safe)
    else
      name
    end.html_safe
  end

  def order_detail_description_as_text(order_detail)
    name = order_detail.product.to_s
    if order_detail.bundle
      name.prepend("#{order_detail.bundle} -- ")
    else
      name
    end.html_safe
  end

  def sortable (column, title = nil)
    title ||= column.titleize
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title, {:sort => column, :dir => direction}, {:class => (column == sort_column ? sort_direction : 'sortable')}
  end

  #
  # Tells whether or not a fulfilled order detail is approaching the end of the 90 day reconcile period
  # Returns true if the order detail is 60+ days fulfilled, false otherwise
  def needs_reconcile_warning?(order_detail)
    !order_detail.reconciled? && order_detail.fulfilled_at && (Time.zone.now.to_date - order_detail.fulfilled_at.to_date).to_i >= 60
  end

  #
  # currency display helpers
  [ :total, :cost, :subsidy ].each do |type|
    define_method("show_actual_#{type}") {|order_detail| show_currency(order_detail, "actual_#{type}") }
    define_method("show_estimated_#{type}") {|order_detail| show_currency(order_detail, "estimated_#{type}") }
  end

  def facility_product_path(facility, product)
    method = "facility_#{product.class.model_name.underscore}_path"
    send(method, facility, product)
  end
  private

  def show_currency(order_detail, method)
    val=order_detail.method(method).call
    val ? h(number_to_currency(val)) : ''
  end

  def menu_facilities
    return [] unless session_user
    session_user.facilities
  end
end
