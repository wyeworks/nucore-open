# frozen_string_literal: true

module ProblemOrderDetailsController

  include OrderDetailsCsvExport

  extend ActiveSupport::Concern

  def assign_price_policies_to_problem_orders
    assign_missing_price_policies(problem_order_details.readonly(false))
    redirect_to show_problems_path
  end

  def show_problems
    order_details = problem_order_details.joins(:order)

    @search_form = TransactionSearch::SearchForm.new(params[:search], defaults: { date_range_field: "ordered_at", allowed_date_fields: ["ordered_at"] })
    searchers = [
      TransactionSearch::ProductSearcher,
      TransactionSearch::AccountSearcher,
      TransactionSearch::OrderedForSearcher,
      TransactionSearch::DateRangeSearcher,
      TransactionSearch::CrossCoreSearcher,
    ]

    @search = TransactionSearch::Searcher.new(*searchers).search(order_details, @search_form)
    @order_details = @search.order_details.preload(:order_status, :assigned_user)

    respond_to do |format|
      format.html { @order_details = @order_details.paginate(page: params[:page]) }
      format.csv { handle_csv_search }
    end
  end

  private

  def assign_missing_price_policies(order_details)
    successfully_assigned =
      PricePolicyMassAssigner.assign_price_policies(order_details)
    flash[:notice] =
      I18n.t("controllers.problem_order_details.assign_price_policies.success",
             count: successfully_assigned.count)
  end

  def problem_order_details
    raise NotImplementedError
  end

end
