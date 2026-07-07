# frozen_string_literal: true

module Nucore
  module ModelErrorRender
    module HelperMethods
      ##
      # Helper method to render model errors
      # Run in the context of a ActionView rendering
      #
      # This is a simplified implementation taken from
      # dynamic_forms
      def error_messages_for(object)
        return if object.blank?
        return if (count = object.errors.count).zero?

        I18n.with_options(:scope => [:activerecord, :errors, :template]) do |locale|
          header_message = locale.t(
            :header, count:, model: object.model_name.human,
          )
          message = locale.t(:body)

          error_messages =
            object.errors.full_messages.map do |msg|
              content_tag(:li, msg)
            end.join.html_safe

          contents = []
          contents << content_tag(:h2, header_message) if header_message.present?
          contents << content_tag(:p, message) if message.present?
          contents << content_tag(:ul, error_messages)

          content_tag(:div, contents.join.html_safe, class: "error-explanation")
        end
      end
    end

    module FormBuilderMethods
      ##
      # Render model errors in a form using the above helper method.
      def error_messages(_options = {})
        @template.error_messages_for(@object)
      end
    end
  end
end
