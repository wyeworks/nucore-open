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

      content_tag :dl, class: "col-md-2" do
        content_tag(:dt, object.class.human_attribute_name(field)) +
          content_tag(:dd, value)
      end
    end
  end

  def estimate_user_options(current_facility)
    users = Estimate.where(facility_id: current_facility.id)
                    .includes(:user)
                    .map { |e| [e.user_display_name, e.user_id] }
                    .uniq
    [[t(".all_users"), ""]] + users
  end
end
