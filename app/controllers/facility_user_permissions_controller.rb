# frozen_string_literal: true

class FacilityUserPermissionsController < ApplicationController

  admin_tab     :all
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :check_granular_permissions_enabled
  before_action { authorize! :manage, FacilityUserPermission }

  layout "two_column"

  def initialize
    @active_tab = "admin_facility"
    super
  end

  # GET /facilities/:facility_id/permissions/search
  def search
  end

  # GET /facilities/:facility_id/permissions/:id/edit
  def edit
    @user = User.find(params[:id])
    @permission = current_facility.facility_user_permissions.find_or_initialize_by(user: @user)
  end

  # PATCH /facilities/:facility_id/permissions/:id
  def update
    @user = User.find(params[:id])
    @permission = current_facility.facility_user_permissions.find_or_initialize_by(user: @user)

    if @permission.update(permission_params)
      if @permission.no_permissions?
        LogEvent.log(@permission, :delete, current_user)
        @permission.destroy
      else
        event_type = @permission.previously_new_record? ? :create : :update
        LogEvent.log(@permission, event_type, current_user, metadata: permission_changes)
      end
      flash[:notice] = text("update.success")
      redirect_to facility_facility_users_path(current_facility)
    else
      flash.now[:alert] = text("update.failure")
      render :edit
    end
  end

  private

  def permission_params
    allowed = FacilityUserPermission::PERMISSIONS
    allowed -= [:assign_permissions] unless current_user.administrator?

    params.require(:facility_user_permission).permit(*allowed)
  end

  def permission_changes
    @permission.previous_changes.slice(*FacilityUserPermission::PERMISSIONS.map(&:to_s))
  end

  def check_granular_permissions_enabled
    raise ActionController::RoutingError, "Granular permissions are not enabled" unless SettingsHelper.feature_on?(:granular_permissions)
  end

end
