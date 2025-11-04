# frozen_string_literal: true

module SecureRooms

  class CardReadersController < ApplicationController

    admin_tab :all

    layout "two_column"

    before_action :check_acting_as
    before_action :init_current_facility
    before_action :init_product
    load_and_authorize_resource through: :product

    def initialize
      @active_tab = "secure_rooms"
      super
    end

    def index
      @card_readers = @product.card_readers
    end

    def new
    end

    def edit
    end

    def create
      if @card_reader.update(card_reader_params)
        flash[:notice] = text("create.success")
        redirect_to facility_secure_room_card_readers_path(current_facility, @product)
      else
        flash.now[:error] = text("create.failure")
        render :new
      end
    end

    def update
      if @card_reader.update(card_reader_params)
        flash[:notice] = text("update.success")
        redirect_to facility_secure_room_card_readers_path(current_facility, @product)
      else
        flash.now[:error] = text("update.failure")
        render :edit
      end
    end

    def destroy
      if @card_reader.destroy
        flash[:notice] = text("destroy.success")
      else
        flash[:error] = text("destroy.failure")
      end
      redirect_to facility_secure_room_card_readers_path(current_facility, @product)
    end

    private

    def init_product
      @product = current_facility.secure_rooms.find_by!(url_name: params[:secure_room_id])
    end

    def card_reader_params
      params.expect(
        card_reader: [:description, :card_reader_number, :control_device_number, :direction_in]
      )
    end

  end

end
