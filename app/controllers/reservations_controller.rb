class ReservationsController < ApplicationController
  customer_tab  :all
  before_filter :authenticate_user!, :except => [ :index ]
  before_filter :check_acting_as,  :only => [ :switch_instrument, :show, :list ]
  before_filter :load_basic_resources, :only => [:new, :create, :edit, :update]
  before_filter :load_and_check_resources, :only => [ :move, :switch_instrument ]

  include TranslationHelper
  include FacilityReservationsHelper

  def initialize
    super
    @active_tab = 'reservations'
  end

  # GET /facilities/1/instruments/1/reservations.js?_=1279579838269&start=1279429200&end=1280034000
  def index
    @facility     = Facility.find_by_url_name!(params[:facility_id])
    @instrument   = @facility.instruments.find_by_url_name!(params[:instrument_id])

    @start_at     = params[:start] ? Time.zone.at(params[:start].to_i) : Time.zone.now
    @start_date   = @start_at.beginning_of_day

    @end_at       = params[:end] ? Time.zone.at(params[:end].to_i) : @start_at.end_of_day

    @reservations = @instrument.schedule.
                                  reservations.
                                  active.
                                  in_range(@start_at, @end_at).
                                  includes(:order_detail => { :order => :user })


    @rules        = @instrument.schedule_rules

    # restrict to available if it requires approval and the user
    # isn't a facility admin
    if @instrument.requires_approval && acting_user && acting_user.cannot_override_restrictions?(@instrument)
      @rules = @rules.available_to_user(acting_user)
    end

    # We're not using unavailable rules for month view
    if @end_at - @start_at <= 1.week
      # build unavailable schedule
      @unavailable = ScheduleRule.unavailable(@rules)
    else
      @unavailable = []
    end

    respond_to do |format|
      as_calendar_object_options = {:start_date => @start_date, :with_details => current_user && params[:with_details]}
      as_calendar_object_options = {:start_date => @start_date, :with_details => params[:with_details]}
      format.js { render :json => @reservations.map{|r| r.as_calendar_object(as_calendar_object_options)}.flatten +
                                  @unavailable.map{ |r| r.as_calendar_object(as_calendar_object_options)}.flatten }
    end
  end

  # GET /reservations
  # All My Resesrvations
  def list
    notices = []

    relation=acting_user.order_details
    in_progress=relation.in_progress_reservations.all
    @status=params[:status]
    @available_statuses = [ in_progress.blank? ? 'upcoming' : 'upcoming &amp; in progress', 'all' ]

    if @status == 'all'
      @order_details = relation.all_reservations.all
    elsif @status == 'upcoming'
      @status=@available_statuses.first
      @order_details = in_progress + relation.upcoming_reservations.all
    else
      return redirect_to reservations_status_path(:status => "upcoming")
    end

    @order_details = @order_details.paginate(:page => params[:page])

    notices = @order_details.collect do |od|
      notice_for_reservation od.reservation
    end
    notices.compact!
    existing_notices = flash[:notice].presence ? [flash[:notice]] : []
    flash.now[:notice] = existing_notices.concat(notices).join('<br />').html_safe unless notices.empty?
  end

  # POST /orders/1/order_details/1/reservations
  def create
    raise ActiveRecord::RecordNotFound unless @reservation.nil?
    @reservation = @order_detail.build_reservation(params[:reservation].merge(:product => @instrument))

    if !@order_detail.bundled? && params[:order_account].blank?
      flash.now[:error]=I18n.t 'controllers.reservations.create.no_selection'
      @reservation.valid? # run validations so it sets reserve_end_at
      set_windows
      render :new and return
      #return redirect_to new_order_order_detail_reservation_path(@order, @order_detail)
    end

    @reservation.transaction do
      begin
        unless params[:order_account].blank?
          account=Account.find(params[:order_account].to_i)
          if account != @order.account
            @order.invalidate
            @order.update_attributes!(:account => account)
          end
        end

        # merge state can change after call to #save! due to OrderDetailObserver#before_save
        mergeable=@order_detail.order.to_be_merged?

        save_reservation_and_order_detail

        flash[:notice] = I18n.t 'controllers.reservations.create.success'

        if mergeable
          # The purchase_order_path or cart_path will handle the backdating, but we need
          # to do this here for merged reservations.
          backdate_reservation_if_necessary
          redirect_to facility_order_path(@order_detail.facility, @order_detail.order.merge_order || @order_detail.order)
        elsif @order_detail.product.is_a?(Instrument) && @order.order_details.count == 1
          redirect_params = {}
          redirect_params[:send_notification] = '1' if params[:send_notification] == '1'
          # only trigger purchase if instrument
          # and is only thing in cart (isn't bundled or on a multi-add order)
          redirect_to purchase_order_path(@order, redirect_params)
        else
          redirect_to cart_path
        end

        return
      rescue ActiveRecord::RecordInvalid => e
        logger.error e.message
        raise ActiveRecord::Rollback
      rescue Exception => e
        logger.error e.message
        flash.now[:error] = I18n.t('orders.purchase.error')
        flash.now[:error] += " #{e.message}" if e.message
        raise ActiveRecord::Rollback
      end
    end
    set_windows
    render :action => "new"
  end

  # GET /orders/1/order_details/1/reservations/new
  def new
    raise ActiveRecord::RecordNotFound unless @reservation.nil?
    @reservation  = @instrument.next_available_reservation || Reservation.new(:product => @instrument, :duration_value => (@instrument.min_reserve_mins.to_i < 15 ? 15 : @instrument.min_reserve_mins), :duration_unit => 'minutes')
    @reservation.round_reservation_times
    flash[:notice] = t_model_error(Instrument, 'acting_as_not_on_approval_list') unless @instrument.is_approved_for?(acting_user)
    set_windows

  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/:id(.:format)
  def show
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @reservation  = Reservation.find(params[:id])

    raise ActiveRecord::RecordNotFound if (@reservation != @order_detail.reservation)
  end

  # GET /orders/1/order_details/1/reservations/1/edit
  def edit
    raise ActiveRecord::RecordNotFound if invalid_for_update?
    set_windows
  end

  # PUT  /orders/1/order_details/1/reservations/1
  def update
    raise ActiveRecord::RecordNotFound if invalid_for_update?

    @reservation.assign_times_from_params(params[:reservation])

    Reservation.transaction do
      begin

        # merge state can change after call to #save! due to OrderDetailObserver#before_save
        mergeable=@order_detail.order.to_be_merged?

        save_reservation_and_order_detail

        flash[:notice] = 'The reservation was successfully updated.'
        if mergeable
          redirect_to facility_order_path(@order_detail.facility, @order_detail.order.merge_order || @order_detail.order)
        else
          redirect_to (@order.purchased? ? reservations_path : cart_path)
        end
        return
      rescue ActiveRecord::RecordInvalid => e
        raise ActiveRecord::Rollback
      end
    end
    set_windows
    render :action => "edit"
  end

  # POST /orders/:order_id/order_details/:order_detail_id/reservations/:reservation_id/move
  def move

    if @reservation.move_to_earliest
      flash[:notice] = 'The reservation was moved successfully.'
    else
      flash[:error] = @reservation.errors.full_messages.join("<br/>")
    end

    redirect_to reservations_status_path(:status => 'upcoming')
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/:reservation_id/move
  def earliest_move_possible
    @reservation       = Reservation.find(params[:reservation_id])
    @earliest_possible = @reservation.earliest_possible

    if @earliest_possible
      @formatted_dates = {
        :start_date => human_date(@earliest_possible.reserve_start_at),
        :start_time => human_time(@earliest_possible.reserve_start_at),
        :end_date   => human_date(@earliest_possible.reserve_end_at),
        :end_time   => human_time(@earliest_possible.reserve_end_at),
      }
    end

    render :layout => false
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/switch_instrument
  def switch_instrument
    authorize! :start_stop, @reservation

    relay_error_msg = 'An error was encountered while attempted to toggle the instrument. Please try again.'
    raise ActiveRecord::RecordNotFound unless params[:switch] && (params[:switch] == 'on' || params[:switch] == 'off')

    begin
      relay = @instrument.relay
      if (params[:switch] == 'on' && @reservation.can_switch_instrument_on?)
        status=Rails.env.production? ? nil : true

        if status.nil?
          relay.activate
          status = relay.get_status
        end

        if status
          @reservation.actual_start_at = Time.zone.now
          @reservation.save!
          flash[:notice] = 'The instrument has been activated successfully'
        else
          raise Exception
        end
        @instrument.instrument_statuses.create(:is_on => status)
      elsif (params[:switch] == 'off' && @reservation.can_switch_instrument_off?)
        status=Rails.env.production? ? nil : false

        if status.nil?
          port=@instrument.relay.port
          relay.deactivate
          status = relay.get_status
        end

        if status == false
          @reservation.actual_end_at = Time.zone.now
          @reservation.save!
          flash[:notice] = 'The instrument has been deactivated successfully'
        else
          raise Exception
        end
        @instrument.instrument_statuses.create(:is_on => status)

        # reservation is done, now give the best price
        @reservation.order_detail.assign_price_policy
        @reservation.order_detail.save!
      else
        raise Exception
      end
    rescue Exception => e
      flash[:error] = relay_error_msg
    end

    if params[:switch] == 'off' && @order_detail.accessories?
      redirect_to new_order_order_detail_accessory_path(@order, @order_detail)
      return
    end

    redirect_to params[:redirect_to] || request.referer || order_order_detail_path(@order, @order_detail)
  end

  private
  def load_basic_resources
    @order_detail = Order.find(params[:order_id]).order_details.find(params[:order_detail_id])
    @order = @order_detail.order
    @reservation = @order_detail.reservation
    @instrument   = @order_detail.product
    @facility = @instrument.facility
    nil
  end
  def load_and_check_resources
    load_basic_resources
    #@reservation  = @instrument.reservations.find_by_id_and_order_detail_id(params[:reservation_id], @order_detail.id)
    raise ActiveRecord::RecordNotFound if @reservation.blank?
  end

  def ability_resource
    return @reservation
  end

  # TODO you shouldn't be able to edit reservations that have passed or are outside of the cancellation period (check to make sure order has been placed)
  def invalid_for_update?
    params[:id].to_i != @reservation.id ||
    @reservation.actual_start_at ||
    @reservation.actual_end_at ||
    !(@reservation.can_edit? || @reservation.can_customer_edit?)
  end

  def save_reservation_and_order_detail
    @reservation.save_as_user!(session_user)
    @order_detail.reload.assign_estimated_price(nil, @reservation.reserve_end_at)
    @order_detail.save_as_user!(session_user)
  end

  def backdate_reservation_if_necessary
    facility_ability = Ability.new(session_user, @order.facility, self)
    if facility_ability.can?(:order_in_past, @order) && @reservation.reserve_end_at < Time.zone.now
      @order_detail.backdate_to_complete!(@reservation.reserve_end_at)
    end
  end

  def set_windows
    @max_window = max_reservation_window
    @max_days_ago = session_user.operator_of?(@facility) ? -365 : 0
    # initialize calendar time constraints
    @min_date     = (Time.zone.now + @max_days_ago.days).strftime("%Y%m%d")
    @max_date     = (Time.zone.now + @max_window.days).strftime("%Y%m%d")
  end

  def max_reservation_window
    return 365 if session_user.operator_of?(@facility)
    @reservation.longest_reservation_window(@order_detail.price_groups)
  end

  def notice_for_reservation(reservation)
    return unless reservation

    if reservation.can_switch_instrument_off? # do you need to click stop
      I18n.t('reservations.notices.can_switch_off', :reservation => reservation)
    elsif reservation.can_switch_instrument_on? # do you need to begin your reservation
      I18n.t('reservations.notices.can_switch_on', :reservation => reservation)
    elsif reservation.cancelled?
      # no message
    # do you have a reservation for today that hasn't ended
    elsif upcoming_today? reservation
      I18n.t('reservations.notices.upcoming', :reservation => reservation)
    end
  end

  def upcoming_today?(reservation)
    now = Time.zone.now
    (reservation.reserve_start_at.to_date == now.to_date || reservation.reserve_start_at < now) && reservation.reserve_end_at > now
  end

  def helpers
    ActionController::Base.helpers
  end
end
