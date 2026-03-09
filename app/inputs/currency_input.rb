# frozen_string_literal: true

class CurrencyInput < SimpleForm::Inputs::Base

  include ActionView::Helpers::NumberHelper

  def input(_wrapper_options)
    set_value
    input_html_options[:class] = Array(input_html_options[:class]) + ["form-control"]

    out = template.content_tag :div, class: ["input-prepend", "currency-input"] do
      template.content_tag(:span, "$", class: "add-on") +
        @builder.text_field(attribute_name, input_html_options)
    end
    out.html_safe
  end

  private

  def set_value
    value = input_html_options[:value] || object.send(attribute_name)
    input_html_options[:value] = number_with_precision(value, precision: 2)
  end

end
