# frozen_string_literal: true

require "nucore/model_error_render"

ActionView::Helpers::FormBuilder.include(
  Nucore::ModelErrorRender::FormBuilderMethods
)
