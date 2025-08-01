# frozen_string_literal: true

class UserResearchSafetyCertificationsController < ApplicationController

  admin_tab     :all
  before_action :check_acting_as
  before_action :init_current_facility

  layout "two_column"

  def initialize
    @active_tab = "admin_users"
    super
  end

  def index
    @user = User.find(params[:user_id])
    begin
      @certificates = ResearchSafetyCertificationLookup.certificates_with_status_for(@user)
    rescue ResearchSafetyAdapters::ScishieldApiError => e
      flash[:error] = e.message
    end
  end

  # During rendering, we want to use the Ability as if we were using the UsersController
  def current_ability
    ::Ability.new(current_user, current_facility, UsersController.new)
  end

end
