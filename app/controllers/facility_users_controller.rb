# frozen_string_literal: true

class FacilityUsersController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility

  load_and_authorize_resource class: User

  layout "two_column"

  def initialize
    @active_tab = "admin_facility"
    super
  end

  # GET /facilities/:facility_id/facility_users
  def index
    @users = User.find_users_by_facility(current_facility)
  end

  # DELETE /facilities/:facility_id/facility_users/:facility_user_id/map_user
  # remove the user's facility-role mapping
  def destroy
    @user = User.find(params[:id])
    destroyed = @user.facility_user_roles(current_facility).destroy_all
    destroyed.each { |user_role| LogEvent.log(user_role, :delete, current_user) }

    redirect_to facility_facility_users_url
  end

  def search
  end

  # GET /facilities/:facility_id/facility_users/:facility_user_id/map_user
  def map_user
    @user = User.find(params[:facility_user_id])

    if request.post?
      begin
        @user_role = UserRole.grant(@user, params[:user_role][:role], current_facility)
        LogEvent.log(@user_role, :create, current_user)
        redirect_to facility_facility_users_url
      rescue ActiveRecord::RecordInvalid => e
        flash.now[:alert] = e.message
        render action: "map_user"
      end
    end
  end

end
