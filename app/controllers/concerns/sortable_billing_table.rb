# frozen_string_literal: true

module SortableBillingTable

  extend ActiveSupport::Concern

  include SortableColumnController

  # Default to "desc" sorting direction
  def sort_direction
    params[:dir] == "asc" ? "asc" : "desc"
  end

  def apply_sort_joins(order_details)
    if sort_column == "pricing_group"
      order_details.joins(account: :price_group_members).joins("LEFT JOIN price_groups ON price_groups.id = price_group_members.price_group_id")
    else
      order_details
    end
  end

  def sort_lookup_hash
    @sort_lookup_hash ||=
      if @extra_date_column
        { @extra_date_column.to_s => "order_details.#{@extra_date_column}" }.merge(default_sort_lookup_hash)
      else
        default_sort_lookup_hash
      end
  end

  def default_sort_lookup_hash
    {
      "date_range_field" => "order_details.#{order_detail_date_range_field}",
      "order_number" => ["order_details.order_id", "order_details.id"],
      "order_detail_number" => "order_details.id",
      "ordered_for" => ["users.last_name", "order_details.fulfilled_at"],
      "payment_source" => "order_details.account_id",
      "pricing_group" => "price_groups.name",
      "order_status" => "order_details.order_status_id",
    }.tap do |hash|
      # journal_or_statement_date sorting is handled in DateRangeSearcher
      hash.delete "date_range_field" if order_detail_date_range_field == "journal_or_statement_date"
    end
  end

  def enable_sorting
    @sorting_enabled = true
  end

  def order_detail_date_range_field
    @date_range_field || "fulfilled_at"
  end

end
