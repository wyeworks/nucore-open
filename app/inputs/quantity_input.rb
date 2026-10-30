# frozen_string_literal: true

class QuantityInput < SimpleForm::Inputs::FileInput
  def input(_wrapper_options)
    input_html_options[:class] << "timeinput" if object.quantity_as_time?
    @builder.text_field(attribute_name, input_html_options).html_safe
  end
end
