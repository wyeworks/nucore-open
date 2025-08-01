# frozen_string_literal: true

module SecureRooms
  # NU needs this information to maintain these devices on the protected subnet
  # they created to host them. Storing this info in NUcore will make it easier
  # to debug issues and maintain consistency of this data.
  class EthernetPortsController < ApplicationController

    admin_tab :all

    before_action :init_current_facility
    before_action :init_product
    before_action :check_acting_as

    layout "two_column"

    def edit
    end

    def update
      respond_to do |format|
        if @product.update(ethernet_resource_params)
          flash[:notice] = "Secure room ethernet ports were successfully updated."
          format.html { redirect_to(facility_secure_room_card_readers_path(@current_facility, @product)) }
        else
          format.html { render action: "edit" }
        end
      end
    end

    private

    def init_product
      @product = current_facility.secure_rooms.find_by!(url_name: params[:secure_room_id])
    end

    def ethernet_resource_params
      params.require("secure_room").permit(:card_reader_room_number,
                                           :card_reader_circuit_number,
                                           :card_reader_port_number,
                                           :card_reader_location_description,
                                           :tablet_room_number,
                                           :tablet_circuit_number,
                                           :tablet_port_number,
                                           :tablet_location_description)
    end
  end
end
