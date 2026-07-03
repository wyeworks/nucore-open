# frozen_string_literal: true

# Native HTML5 date input (browser's built-in picker). Submits values in ISO
# format (yyyy-mm-dd), so no server-side parsing is needed.
#
# Usage:
#   = f.input :starts_at, as: :date_field
#   = f.input :expires_at, as: :date_field, min_date: Date.current
class DateFieldInput < SimpleForm::Inputs::Base
  def input(_wrapper_options)
    date = object.public_send(attribute_name)&.to_date

    html_options = input_html_options.merge(
      value: date&.iso8601, class: "form-control",
    )
    html_options[:min] = options[:min_date].to_date.iso8601 if options[:min_date]
    html_options[:max] = options[:max_date].to_date.iso8601 if options[:max_date]

    @builder.date_field attribute_name, html_options
  end
end
