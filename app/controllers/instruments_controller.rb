# frozen_string_literal: true

class InstrumentsController < ProductsCommonController

  customer_tab :show, :public_schedule, :public_list
  admin_tab :create, :new, :edit, :index, :manage, :update, :manage, :schedule
  before_action :store_fullpath_in_session, only: [:index, :show]
  before_action :set_default_lock_window, only: [:create, :update]

  # public_schedule does not require login
  skip_before_action :authenticate_user!, only: [:public_schedule, :public_list]
  skip_authorize_resource only: [:public_schedule, :public_list]

  skip_before_action :init_product, only: [:instrument_statuses, :public_list]

  # GET /facilities/:facility_id/instruments/list
  def public_list
    @instruments = Instrument.active.in_active_facility.order(:name).includes(:facility)
    @active_tab = "home"
    render layout: "application"
  end

  # GET /facilities/:facility_id/instruments/:instrument_id
  def show
    instrument_for_cart = InstrumentForCart.new(@product)
    # TODO: Remove this instance variable-not used anywhere but tests
    @add_to_cart = instrument_for_cart.purchasable_by?(acting_user, session_user)
    if @add_to_cart
      redirect_to new_facility_instrument_single_reservation_path(current_facility, @product)
    elsif instrument_for_cart.error_path
      redirect_to instrument_for_cart.error_path, notice: instrument_for_cart.error_message
    else
      flash.now[:notice] = instrument_for_cart.error_message if instrument_for_cart.error_message
      render layout: "application"
    end
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/schedule
  def schedule
    @admin_reservations =
      @product
      .reservations
      .admin_and_offline
      .ends_in_the_future
      .order(:reserve_start_at)
  end

  def public_schedule
    render layout: "application"
  end

  def set_default_lock_window
    if params[:instrument][:lock_window].blank?
      params[:instrument][:lock_window] = 0
    end
  end

  def instrument_statuses
    @instrument_statuses = InstrumentStatusFetcher.new(current_facility).statuses
    render json: @instrument_statuses
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/switch
  def switch
    raise ActiveRecord::RecordNotFound unless params[:switch] && (params[:switch] == "on" || params[:switch] == "off")

    begin
      relay = @product.relay
      status = true

      if SettingsHelper.relays_enabled_for_admin?
        status = (params[:switch] == "on" ? relay.activate : relay.deactivate)
      end

      @status = @product.instrument_statuses.create!(is_on: status)
    rescue => e
      logger.error "ERROR: #{e.message}"
      @status = InstrumentStatus.new(instrument: @product, error_message: e.message)
      # raise ActiveRecord::RecordNotFound
    end
    render json: @status
  end

end
