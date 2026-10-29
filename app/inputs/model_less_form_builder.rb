# frozen_string_literal: true

class ModelLessFormBuilder < SimpleForm::FormBuilder
  def input(attribute_name, options = {}, &block)
    merged_options = { input_html: { id: attribute_name, name: attribute_name } }.deep_merge!(options)
    options.replace(merged_options)
    super
  end
end
