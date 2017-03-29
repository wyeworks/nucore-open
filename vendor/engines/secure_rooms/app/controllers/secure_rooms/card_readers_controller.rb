module SecureRooms

  class CardReadersController < ApplicationController

    admin_tab :all

    layout "two_column"

    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :authorize_card_reader
    before_action :init_current_facility
    before_action :init_product
    before_action :load_card_reader, except: [:index]

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
      if @card_reader.update_attributes(card_reader_params)
        flash[:notice] = text("create.success")
        redirect_to facility_secure_room_card_readers_path(current_facility, @product)
      else
        flash.now[:error] = text("create.failure")
        render :new
      end
    end

    def update
      if @card_reader.update_attributes(card_reader_params)
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

    def authorize_card_reader
      authorize! :manage, CardReader
    end

    def init_product
      @product = current_facility.products(SecureRoom).find_by!(url_name: params[:secure_room_id])
    end

    def load_card_reader
      scope = @product.card_readers
      @card_reader = params[:id] ? scope.find(params[:id]) : scope.build
    end

    def card_reader_params
      params.require(:card_reader).permit(:description, :card_reader_number, :control_device_number)
    end

  end

end
