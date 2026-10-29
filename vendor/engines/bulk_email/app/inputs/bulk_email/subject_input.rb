# frozen_string_literal: true

module BulkEmail
  class SubjectInput < SimpleForm::Inputs::TextInput
    def input(_wrapper_options)
      template.content_tag(:div, class: "input-prepend") do
        template.content_tag(:span, options[:prefix], class: "add-on") +
          @builder.text_field(attribute_name, input_html_options)
      end
    end
  end
end
