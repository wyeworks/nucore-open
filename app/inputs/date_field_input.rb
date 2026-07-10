# frozen_string_literal: true

# Native HTML5 date input (browser's built-in picker). Submits values in ISO
# format (yyyy-mm-dd), so no server-side parsing is needed.
#
# Usage:
#   = f.input :starts_at, as: :date_field
#   = f.input :expires_at, as: :date_field, min_date: Date.current
#   = f.input :fulfilled_at, as: :date_field, min_date: x, max_date: y, input_html: { class: "js--hook" }
#
# An explicit input_html[:value] is respected as-is (must already be ISO); otherwise
# the value is read from the object and normalized to ISO.
class DateFieldInput < SimpleForm::Inputs::Base
  def input(_wrapper_options)
    html_options = input_html_options.dup

    unless html_options.key?(:value)
      date = object.public_send(attribute_name)&.to_date
      html_options[:value] = date&.iso8601
    end

    html_options[:class] = [*html_options[:class], "form-control"].uniq.join(" ")
    html_options[:min] ||= options[:min_date]&.to_date&.iso8601
    html_options[:max] ||= options[:max_date]&.to_date&.iso8601

    @builder.date_field attribute_name, html_options
  end
end
