# frozen_string_literal: true

module BulkEmail
  class BodyInput < SimpleForm::Inputs::TextInput
    def input(_wrapper_options)
      safe_join([
                  readonly_text(options[:greeting]),
                  @builder.text_area(attribute_name, input_html_options),
                  readonly_text(options[:signoff]),
                ])
    end

    private

    def readonly_text(content)
      return if content.blank?
      rows = content.count("\n") + 1
      template.content_tag(:textarea, content, input_html_options.merge(disabled: true, rows:))
    end
  end
end
