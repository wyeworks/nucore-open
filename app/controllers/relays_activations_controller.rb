# frozen_string_literal: true

class RelaysActivationsController < ApplicationController

  before_action :authenticate_user!
  before_action :init_current_facility
  authorize_resource :facility

  def create
    LogEvent.log(current_facility, :activate, current_user)
    relays.each(&:activate)
    redirect_to facility_instruments_path(current_facility), flash: { notice: text("turned_on") }
  rescue NetBooter::Error => e
    ActiveSupport::Notifications.instrument(
        "background_error",
        exception: e
    )
    redirect_to facility_instruments_path(current_facility), flash: { alert: text("connection_error") }
  end

  def destroy
    LogEvent.log(current_facility, :deactivate, current_user)
    relays.each(&:deactivate)
    redirect_to facility_instruments_path(current_facility), flash: { notice: text("turned_off") }
  rescue NetBooter::Error => e
    ActiveSupport::Notifications.instrument("background_error", exception: e)
    redirect_to facility_instruments_path(current_facility), flash: { alert: text("connection_error") }
  end

  private

  def relays
    current_facility.instruments.includes(:relay).select(&:has_real_relay?).map(&:relay)
  end

end
