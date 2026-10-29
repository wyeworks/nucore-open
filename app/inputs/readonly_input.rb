# frozen_string_literal: true

class ReadonlyInput < SimpleForm::Inputs::Base
  include DateHelper
  include ActionView::Helpers::SanitizeHelper

  disable :required

  def input(_wrapper_options)
    classes = [*input_html_options[:class]]
    template.content_tag :div, class: classes do
      value = input_html_options[:value] || object.send(attribute_name)
      value = process_datetime(value) if value.class <= ActiveSupport::TimeWithZone
      value = process_boolean(value)  if !!value == value # is it a boolean
      value = options.delete(:value_method).call(value) if options[:value_method].is_a?(Proc)
      value = value.send(options[:value_method] || :to_s)
      value = sanitize(value.to_s)
      value.presence || options[:default_value]
    end
  end

  private

  def process_datetime(datetime)
    return nil if datetime.blank?
    begin
      if options[:date_only]
        format_usa_date(datetime)
      else
        format_usa_datetime(datetime)
      end
    rescue
      ""
    end
  end

  def process_boolean(value)
    value ? I18n.t("boolean.true") : I18n.t("boolean.false")
  end
end
