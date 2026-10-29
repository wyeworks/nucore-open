# frozen_string_literal: true

module FormHelper
  def readonly_form_for(record_name, record = nil, options = {}, &block)
    if record.is_a?(Hash) && record.extractable_options?
      options = record
      record = nil
    end
    record ||= instance_variable_get("@#{record_name}")
    options[:builder] = ReadonlyFormBuilder
    simple_fields_for(record_name, record, options, &block)
  end

  def modelless_form_for(options = {}, &block)
    options[:builder] = ModelLessFormBuilder
    simple_form_for(options[:object] || "", options, &block)
  end

  def scheduling_group_select(product, user)
    select_tag "product_access_group[#{product.id}]",
               scheduling_group_options(product.product_access_groups, product.access_group_for_user(user)),
               include_blank: true
  end

  def scheduling_group_options(access_groups, selected_access_group)
    options_from_collection_for_select(access_groups, :id, :name, selected_access_group.try(:id))
  end
end
