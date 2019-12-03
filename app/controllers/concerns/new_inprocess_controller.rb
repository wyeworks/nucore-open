# frozen_string_literal: true

module NewInprocessController

  include OrderDetailsCsvExport

  def index
    order_details = new_or_in_process_orders.joins(:order)

    @search_form = TransactionSearch::SearchForm.new(params[:search], defaults: { date_range_field: "ordered_at", allowed_date_fields: ["ordered_at"] })
    @search = TransactionSearch::Searcher.new(TransactionSearch::ProductSearcher,
                                              TransactionSearch::OrderedForSearcher,
                                              TransactionSearch::OrderStatusSearcher,
                                              TransactionSearch::DateRangeSearcher).search(order_details, @search_form)
    @order_details = @search.order_details.includes(:order_status).joins_assigned_users.reorder(sort_clause)

    respond_to do |format|
      format.html { @order_details = @order_details.paginate(page: params[:page]) }
      format.csv { handle_csv_search }
    end
  end

  private

  def new_or_in_process_orders
    raise NotImplementedError
  end

  def sort_lookup_hash
    {
      "order_number" => ["order_details.order_id", "order_details.id"],
      "assigned_to" => ["assigned_users.last_name", "assigned_users.first_name", "order_statuses.name", "order_details.ordered_at"],
      "ordered_at" => "order_details.ordered_at",
      "ordered_for" => ["#{User.table_name}.last_name", "#{User.table_name}.first_name"],
      "product_name" => ["products.name", "order_details.state", "order_details.ordered_at"],
      "reserve_range" => ["reservations.reserve_start_at", "reservations.reserve_end_at"],
      "status" => "order_statuses.name",
      "payment_source" => "accounts.description",
    }
  end

end
