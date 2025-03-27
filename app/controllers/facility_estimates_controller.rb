# frozen_string_literal: true

class FacilityEstimatesController < ApplicationController

  admin_tab :all
  before_action { @active_tab = "admin_estimates" }
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility

  def index

  end
end
