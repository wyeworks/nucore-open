# frozen_string_literal: true

module ReservationSwitch

  extend ActiveSupport::Concern

  def switch_instrument!(switch)
    case
    when switch == "on"
      switch_instrument_on!
    when switch == "off"
      switch_instrument_off!
    end
  rescue AASM::InvalidTransition => e
    if e.failures.include?(:time_data_completeable?)
      respond_error(text("switch_instrument.prior_is_still_running"))
    else
      respond_error(e.message)
    end
  rescue => e
    respond_error(e.message)
  end

  def respond_error(message)
    flash[:error] = message
  end

  def switch_instrument_off!
    unless @reservation.other_reservation_using_relay?
      ReservationInstrumentSwitcher.new(@reservation).switch_off!
      flash[:notice] = switch_off_success
    end
    session[:reservation_auto_logout] = true if params[:reservation_ended].present?
  end

  def switch_instrument_on!
    ReservationInstrumentSwitcher.new(@reservation).switch_on!
    flash[:notice] = "The instrument has been activated successfully"
    session[:reservation_auto_logout] = true if params[:reservation_started].present?
  end

  def switch_value_present?
    params[:switch] && (params[:switch] == "on" || params[:switch] == "off")
  end

  def switch_off_success
    "The instrument has been deactivated successfully"
  end

end
