class InstrumentsDashboardController < ApplicationController

  layout "plain", only: :public_dashboard

  admin_tab :all
  before_action :authenticate_user!, except: :public_dashboard
  before_action :authenticate_token, only: :public_dashboard
  before_action :init_reservations
  # This sets "Reservations" as the active tab
  before_action { @active_tab = "admin_reservations" }

  def dashboard
    authorize!(:show, Reservation)
  end

  def public_dashboard
    if params[:refresh]
      render partial: "dashboard", locals: { reservations: @reservations }
    end
  end

  private

  def init_reservations
    @reservations = current_facility.reservations
      .current_in_use
      .includes(:product, order: :user)
      .joins(instrument: :schedule)
      .merge(Schedule.positioned)
  end

  def authenticate_token
    raise ActiveRecord::RecordNotFound unless current_facility.dashboard_enabled? && params[:token] == current_facility.dashboard_token
  end

end
