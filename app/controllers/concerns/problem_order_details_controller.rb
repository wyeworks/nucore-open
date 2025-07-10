# frozen_string_literal: true

module ProblemOrderDetailsController

  include OrderDetailsCsvExport

  extend ActiveSupport::Concern

  included do
    before_action :authorize_show_problems, only: [:send_problem_notifications, :notification_count]
  end

  def assign_price_policies_to_problem_orders
    assign_missing_price_policies(problem_order_details.readonly(false))
    redirect_to show_problems_path
  end

  def send_problem_notifications
    order_detail_ids, notification_groups = notification_params

    if order_detail_ids.empty?
      flash[:error] = t("shared.problem_order_details.send_notifications.no_selection")
    elsif notification_groups.empty?
      flash[:error] = t("shared.problem_order_details.send_notifications.no_groups")
    else
      sender = build_sender(order_detail_ids, notification_groups)
      sent_count = sender.send_notifications
      flash[:notice] = t("shared.problem_order_details.send_notifications.success", count: sent_count)
    end

    redirect_to show_problems_path
  end

  def notification_count
    order_detail_ids, notification_groups = notification_params

    if order_detail_ids.empty? || notification_groups.empty?
      render json: { emails: 0, users: 0 }
      nil
    else
      sender = build_sender(order_detail_ids, notification_groups)
      counts = sender.detailed_notification_count
      render json: counts
    end
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

  def notification_params
    permitted_params = params.permit(order_detail_ids: [], notification_groups: [])
    [
      permitted_params[:order_detail_ids] || [],
      permitted_params[:notification_groups] || []
    ]
  end

  def build_sender(order_detail_ids, notification_groups)
    order_details = problem_order_details.where(id: order_detail_ids)
    ProblemNotificationSender.new(
      order_details,
      current_user,
      notification_groups: notification_groups.map(&:to_sym)
    )
  end

  def authorize_show_problems
    authorize! :show_problems, Order
  end

end
