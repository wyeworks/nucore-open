# frozen_string_literal: true

# For generating a datepicker widget (no time inputs) using datepicker-data.js
#
# Usage:
#   = f.input :starts_at, as: :date_picker
class DatePickerInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    date_time = object.public_send(attribute_name)
    value = I18n.l(date_time.to_date, format: :usa) if date_time.present?

    min_date = options[:min_date]

    html_options = input_html_options.merge(
      value:, class: "datepicker__data form-control",
    )
    html_options[:data] = { min_date: min_date } if min_date

    @builder.text_field attribute_name, html_options
  end
end
