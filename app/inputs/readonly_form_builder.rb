# frozen_string_literal: true

class ReadonlyFormBuilder < SimpleForm::FormBuilder
  def input(attribute_name, options = {}, &)
    options[:as] = :readonly
    super
  end
end
