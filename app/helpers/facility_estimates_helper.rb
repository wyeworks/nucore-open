# frozen_string_literal: true

module FacilityEstimatesHelper

  def header_display_date(object, field)
    header_display(object, field) do |value|
      value = format_usa_date(value)
      value = yield(value) if value && block_given?
      value
    end
  end

  def header_display(object, field)
    if value = object.send(:try, field)
      value = yield(value) if block_given?

      content_tag :dl, class: "span2" do
        content_tag(:dt, object.class.human_attribute_name(field)) +
          content_tag(:dd, value)
      end
    end
  end

end
