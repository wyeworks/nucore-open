# frozen_string_literal: true

class InstrumentRelaysController < ApplicationController

  admin_tab :all
  before_action :check_acting_as
  before_action :init_instrument
  before_action :manage

  layout "two_column"

  # GET /facilities/:facility_id/instrument/:instrument_id/relays
  # This will return either 1 or 0 relays for the given instrument
  def index
  end

  # GET /facilities/:facility_id/instrument/:instrument_id/relays/:id/edit
  def edit
    @relay = @product.relay
  end

  def update
    handle_relay("edit")
  end

  # GET /facilities/:facility_id/instrument/:instrument_id/relays/new
  def new
    @relay = @product.build_relay
  end

  def create
    handle_relay("new")
  end

  private

  def handle_relay(action_string)
    @relay = @product.replace_relay(relay_params, params[:relay][:control_mechanism])
    if @relay.valid?
      @relay.try(:activate_secondary_outlet) if @relay.secondary_outlet.present?

      LogEvent.log(@relay, :update, current_user, metadata: { instrument_name: @product.name }) if action_string == "edit"

      flash[:notice] = "Relay was successfully updated."
      redirect_to facility_instrument_relays_path(current_facility, @product)
    else
      render action: action_string
    end
  end

  def init_instrument
    @product = current_facility.instruments.find_by!(url_name: params[:instrument_id])
  end

  def manage
    authorize! :view_details, @product
    @active_tab = "admin_products"
  end

  def relay_params
    params.require(:relay)
          .except(:control_mechanism)
          .permit(:ip,
                  :ip_port,
                  :outlet,
                  :secondary_outlet,
                  :username,
                  :password,
                  :type,
                  :auto_logout,
                  :auto_logout_minutes,
                  :id,
                  :mac_address,
                  :building_room_number,
                  :circuit_number,
                  :ethernet_port_number)
  end

end
