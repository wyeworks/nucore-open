# frozen_string_literal: true

class ProjectsController < ApplicationController
  include SortableColumnController

  admin_tab :all
  before_action { @active_tab = action_name || "admin_projects" }

  load_and_authorize_resource through: :current_facility, except: [:show, :edit, :update]
  load_and_authorize_resource only: [:show, :edit, :update]

  def index
    raise ActionController::RoutingError, "Projects are only available in a facility context" unless current_facility

    @search_form = ProjectsSearch::SearchForm.new(
      params[:search],
      defaults: {
        current_facility_id: current_facility.id,
      },
    )

    @search = ProjectsSearch::Searcher.search(nil, @search_form)
    @projects = @search.projects.display_order

    respond_to do |format|
      format.html { @projects = @projects.paginate(page: params[:page]) }
    end
  end

  def cross_core_orders
    raise ActionController::RoutingError, "Projects are only available in a facility context" unless current_facility

    @all_projects = @projects.display_order

    order_details = cross_core_order_details

    @search_form = TransactionSearch::SearchForm.new(
      params[:search],
      defaults: {
        date_range_field: "ordered_at",
        allowed_date_fields: ["ordered_at"],
        cross_core_facilties: "other",
        order_statuses: default_order_statuses(order_details),
        current_facility_id: current_facility.id,
      }
    )

    searchers = [
      TransactionSearch::ProductSearcher,
      TransactionSearch::OrderedForSearcher,
      TransactionSearch::OrderStatusSearcher,
      TransactionSearch::DateRangeSearcher,
      ProjectsSearch::CrossCoreFacilitySearcher,
    ]

    @search = TransactionSearch::Searcher.new(*searchers).search(order_details, @search_form)
    @order_details = @search.order_details.includes(:order_status).reorder(sort_clause)

    respond_to do |format|
      format.html { @order_details = @order_details.paginate(page: params[:page]) }
    end
  end

  def new
  end

  def backend?
    true
  end

  def create
    @project = current_facility.projects.new(project_params)
    render action: :new unless save_project
  end

  def edit
  end

  def show
    @order_details = @project.order_details.order(ordered_at: :desc).paginate(page: params[:page])
  end

  def update
    @project.attributes = project_params
    render action: :edit unless save_project
  end

  private

  def default_order_statuses(order_details)
    TransactionSearch::OrderStatusSearcher.new(order_details).options - [OrderStatus.canceled, OrderStatus.reconciled].map(&:id)
  end

  # Fetch ALL cross core order details related to the current facility
  # Includes all order details from any cross core project that is associated with the current facility,
  # and also all order details from any cross core project that includes an order from the current facility.
  def cross_core_order_details
    projects = Project.for_facility(current_facility)
    OrderDetail.cross_core
      .where(orders: { cross_core_project_id: projects })
  end

  def sort_lookup_hash
    {
      "facility" => "facilities.name",
      "order_number" => ["order_details.order_id", "order_details.id"],
      "ordered_at" => "order_details.ordered_at",
      "status" => "order_statuses.name",
    }
  end

  def project_params
    params.require(:project).permit("active", "description", "name")
  end

  def save_project
    if @project.save
      flash[:notice] =
        text(".#{action_name}.success", project_name: @project.name)
      redirect_to facility_project_path(current_facility, @project)
    end
  end

  def ability_resource
    if ["show", "edit", "update"].include?(params[:action])
      @project
    else
      current_facility
    end
  end

end
