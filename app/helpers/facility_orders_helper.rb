# frozen_string_literal: true

module FacilityOrdersHelper

  def order_detail_badges(order_detail)
    OrderDetailNoticePresenter.new(order_detail).badges_to_html
  end

  def order_detail_status_badges(order_detail)
    # Only return status badges, no warning (problem order) badges
    OrderDetailNoticePresenter.new(order_detail).badges_to_html(only: :status)
  end

  def banner_date_label(object, field, label = nil)
    banner_label(object, field, label) do |value|
      value = format_usa_datetime(value)
      value = yield(value) if value && block_given?
      value
    end
  end

  def banner_label(object, field, label = nil)
    if value = object.send(:try, field)
      value = yield(value) if block_given?

      content_tag :dl, class: "col-md-2" do
        content_tag(:dt, label || object.class.human_attribute_name(field)) +
          content_tag(:dd, value)
      end
    end
  end

end
