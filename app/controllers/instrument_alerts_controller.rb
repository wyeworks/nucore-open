# frozen_string_literal: true

class InstrumentAlertsController < ApplicationController

  admin_tab :all
  layout "two_column"

  before_action :check_acting_as
  before_action :load_instrument

  def new
    @instrument_alert = @instrument.build_alert
  end

  def create
    @instrument_alert = @instrument.build_alert(instrument_alert_params)

    if @instrument_alert.save
      redirect_to facility_instrument_schedule_path(current_facility, @instrument), notice: text("created")
    else
      render action: "new"
    end
  end

  def destroy
    @instrument.alert.destroy
    redirect_to facility_instrument_schedule_path(current_facility, @instrument), notice: text("destroyed")
  end

  private

  def load_instrument
    @instrument = current_facility.instruments.find_by!(url_name: params[:instrument_id])
  end

  def instrument_alert_params
    params.expect(instrument_alert: [:note])
  end

end
