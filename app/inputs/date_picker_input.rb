# frozen_string_literal: true

# For generating a datepicker widget (no time inputs) using datepicker-data.js
#
# Usage:
#   = f.input :starts_at, as: :date_picker
class DatePickerInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    date_time = object.public_send(attribute_name)
    value = I18n.l(date_time.to_date, format: :usa) if date_time.present?
    @builder.text_field attribute_name, input_html_options.merge(value: value, class: "datepicker__data")
  end
end
