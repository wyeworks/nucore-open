# frozen_string_literal: true

module Projects

  class ProjectsController < ApplicationController
    include SortableColumnController

    admin_tab :all
    before_action { @active_tab = action_name || "admin_projects" }

    load_and_authorize_resource through: :current_facility

    def index
      @all_projects = @projects.display_order
      @projects = @all_projects.active.paginate(page: params[:page])
    end

    def inactive
      @all_projects = @projects.display_order
      @projects = @all_projects.inactive.paginate(page: params[:page])
      render action: :index
    end

    def cross_core_orders
      @all_projects = @projects.display_order

      order_details = cross_core_order_details

      @search_form = TransactionSearch::SearchForm.new(params[:search], defaults: { date_range_field: "ordered_at", allowed_date_fields: ["ordered_at"], cross_core_facilties: "other", current_facility_id: current_facility.id })
      searchers = [
        TransactionSearch::ProductSearcher,
        TransactionSearch::OrderedForSearcher,
        TransactionSearch::OrderStatusSearcher,
        TransactionSearch::DateRangeSearcher,
        CrossCoreFacilitySearcher,
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

    def showing_inactive?
      action_name == "inactive"
    end
    helper_method :showing_inactive?

    private

    def cross_core_order_details
      project_ids = current_facility.order_details.joins(:order).pluck(:cross_core_project_id).compact.uniq

      OrderDetail
        .joins(:order)
        .joins(order: :facility)
        .where(orders: { cross_core_project_id: project_ids })
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
      params.require(:projects_project).permit("active", "description", "name")
    end

    def save_project
      if @project.save
        flash[:notice] =
          text(".#{action_name}.success", project_name: @project.name)
        redirect_to facility_project_path(@project.facility, @project)
      end
    end

  end

end
