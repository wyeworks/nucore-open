# frozen_string_literal: true

# DateTimeInput
class TimeDropdownInput < SimpleForm::Inputs::Base

  def input(wrapper_options)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    value = object.public_send("#{attribute_name}_date_time_data")
    @builder.simple_fields_for attribute_name, value, defaults: { include_blank: value.present?, label: false } do |f|
      template.safe_join(
        [
          date_field(f),
          time_fields(f, merged_input_options),
        ],
      )
    end
  end

  private

  def date_field(f)
    f.input :date, as: :date_field
  end

  def time_fields(f, merged_input_options)
    f.input :time_select do
      template.content_tag :div, class: "time-select" do
        template.safe_join(
          [
            f.input_field(:hour, merged_input_options.merge(collection: (1..12).to_a)),
            f.input_field(:minute, merged_input_options.merge(collection: minute_options)),
            f.input_field(:ampm, merged_input_options.merge(collection: %w(AM PM))),
          ],
        )
      end
    end
  end

  def minute_options
    step = options[:minute_step] || 1
    (0..59).step(step).map { |d| [format("%02d", d), d] }
  end

end
