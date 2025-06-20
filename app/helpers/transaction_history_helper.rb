# frozen_string_literal: true

module TransactionHistoryHelper

  def row_class(order_detail)
    OrderDetailPresenter.new(order_detail).row_class
  end

  def product_options(products, search_fields)
    search_fields.map!(&:to_s) if search_fields
    options = []
    products.each do |product|
      options << [product.name, product.id, { "data-facility": product.facility_id,
                                              "data-restricted": product.requires_approval?,
                                              "data-product-type": product.type.downcase }]
    end
    options_for_select options, selected: search_fields
  end

  def order_statuses_options(order_statuses, search_fields)
    search_fields.map!(&:to_s) if search_fields
    options = []
    order_statuses.each do |order_status|
      attributes = {}
      attributes["data-facility"] = order_status.facility_id if order_status.facility_id

      options << [order_status.name, order_status.id, attributes]
    end
    options_for_select options, selected: search_fields
  end

  def chosen_field(field, label, value_field = "id", label_field = "name", from_collection_method = nil)
    var = instance_variable_get("@#{field}")
    enabled = var && var.size > 1
    @search_fields[field] = [var.first.send(value_field.to_sym)] if value_field && var.size == 1
    html = "<li class=\"#{'disabled' unless enabled}\">"
    html << (label_tag field, label.pluralize)
    from_collection = from_collection_method ? send(from_collection_method, var, @search_fields[field]) : options_from_collection_for_select(var, value_field, label_field, @search_fields[field])
    options = { multiple: true, "data-placeholder": "Select #{label.pluralize.downcase}" }
    options[:disabled] = :disabled unless enabled
    html << (select_tag field, from_collection, options)
    html << "</li>"
    html.html_safe
  end

end
