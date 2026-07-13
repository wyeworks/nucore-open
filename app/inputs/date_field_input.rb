# frozen_string_literal: true

# Native HTML5 date input (browser's built-in picker). Submits values in ISO
# format (yyyy-mm-dd), so no server-side parsing is needed.
#
# Usage:
#   = f.input :starts_at, as: :date_field
#   = f.input :expires_at, as: :date_field, min_date: Date.current
#   = f.input :fulfilled_at, as: :date_field, min_date: x, max_date: y, input_html: { class: "js--hook" }
#
# `date_field` renders any Date/Time/date-string value as ISO, so pass date
# objects and let Rails format them — for value, min and max alike.
class DateFieldInput < SimpleForm::Inputs::Base
  def input(_wrapper_options)
    html_options = input_html_options.dup

    html_options[:class] = [*html_options[:class], "form-control"].uniq.join(" ")
    html_options[:min] ||= options[:min_date]
    html_options[:max] ||= options[:max_date]

    @builder.date_field attribute_name, html_options
  end
end
