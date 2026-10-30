# frozen_string_literal: true

# This class is deprecated in favor of TransactionChosenInput. This class
# is still being used by BulkEmailController for searching.
class TransactionChosenOldInput < SimpleForm::Inputs::Base # CollectionSelectInput
  disable :required

  def input(_wrapper_options)
    options[:label_method] ||= :name
    options[:value_method] ||= :id

    # By calling `to_a` here, it fetches the AR::Relation into objects. Since that will
    # happen later anyways, by doing it up front, we prevent extra `count(*)` queries,
    # which were slowing down the page.
    collection_size = collection_items.to_a.size

    select_options = { multiple: true, "data-placeholder": placeholder_label }

    # If there is only one possible value, then we want to show it, and not allow
    # selection, but only if it's not a nullable field
    if collection_size == 1 && !options[:allow_blank]
      search_fields[attribute_name] = [collection_items.first.send(options[:value_method].to_sym)]
      select_options[:disabled] = :disabled
    end

    template.select_tag(attribute_name, option_data, select_options).html_safe
  end

  def label(wrapper_options)
    options[:label] ||= model_label
    super
  end

  private

  def collection_items
    template.instance_variable_get(:@search_options).try(:[], attribute_name)
  end

  def model_label
    attribute_class.model_name.human(count: 2)
  end

  def search_fields
    template.instance_variable_get(:@search_fields)
  end

  def attribute_class
    attribute_name.to_s.classify.constantize
  end

  def placeholder_label
    "Select #{options[:label].capitalize} (leave blank to select all)"
  end

  def option_data
    if options[:data_method]
      template.send(options[:data_method], collection_items, search_fields[attribute_name])
    else
      template.options_from_collection_for_select(collection_items, options[:value_method], options[:label_method], search_fields[attribute_name])
    end
  end
end
