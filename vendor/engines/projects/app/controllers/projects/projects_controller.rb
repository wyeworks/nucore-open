# frozen_string_literal: true

module Projects

  class ProjectsController < ApplicationController

    admin_tab :all
    before_action { @active_tab = "admin_projects" }

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
