# frozen_string_literal: true

class TransactionChosenInput < SimpleForm::Inputs::CollectionInput

  disable :required

  def input(wrapper_options = nil)
    label_method, value_method = detect_collection_methods

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    # By calling `to_a` here, it fetches the AR::Relation into objects. Since that will
    # happen later anyways, by doing it up front, we prevent extra `count(*)` queries,
    # which were slowing down the page.
    collection_size = collection.to_a.size

    merged_input_options[:multiple] = true
    merged_input_options["data-placeholder"] = placeholder_label

    # If there is only one possible value, then we want to show it as selected,
    # but we don't want to allow adding/removing it.
    if collection_size == 1 && !options[:allow_blank]
      input_options[:selected] = [collection.first.public_send(value_method)]
      merged_input_options[:disabled] = :disabled
    end

    option_data = option_elems(label_method, value_method)
    selected = input_options[:selected] || object.public_send(attribute_name) || default_order_statuses
    opts = template.options_for_select option_data, selected: selected
    template.select_tag("#{object.class.model_name.param_key}[#{attribute_name}]", opts, merged_input_options)
  end

  def label(wrapper_options)
    options[:label] ||= model_label
    super
  end

  private

  # Show all available order statuses as selected by default
  def default_order_statuses
    collection.map { |i| i.id.to_s } if attribute_name == "order_statuses"
  end

  # Pass an array if you want arguments, [:full_name, suspended_label: true]
  def option_elems(label_method, value_method)
    collection.map do |i|
      [
        i.public_send(*label_method),
        i.public_send(*value_method),
        data_for_item(i),
      ]
    end
  end

  def data_for_item(item)
    data_proc = options[:data_attrs] || ->(_i) { {} }
    dataify(data_proc.call(item))
  end

  def dataify(hash)
    Hash[
      hash.map { |k, v| ["data-#{k.to_s.dasherize}", v] }
    ]
  end

  def model_label
    attribute_class.model_name.human(count: 2)
  end

  def attribute_class
    attribute_name.to_s.classify.constantize
  end

  def placeholder_label
    "Select #{options[:label].downcase}"
  end

end
