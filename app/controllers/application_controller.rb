# frozen_string_literal: true

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  include DateHelper

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Make the following methods available to all views
  helper_method :cross_facility?
  helper_method :current_facility, :session_user, :manageable_facilities, :operable_facilities, :acting_user, :acting_as?, :check_acting_as, :current_cart, :backend?
  helper_method :open_or_facility_path

  before_action :set_paper_trail_whodunnit

  # Navigation tabs configuration
  attr_accessor :active_tab
  include NavTab

  # return whatever facility is indicated by the :facility_id or :id url parameter
  # UNLESS that url parameter has the value of 'all'
  # in which case, return the all facility
  def current_facility
    facility_id = params[:facility_id] || params[:id]

    @current_facility ||=
      case
      when facility_id.blank?
        nil # TODO: consider a refactoring to use a null object
      when facility_id == Facility.cross_facility.url_name
        Facility.cross_facility
      else
        Facility.find_by(url_name: facility_id)
      end
  end

  def cross_facility? # TODO: try to use current_facility.cross_facility? but note current_facility may be nil
    current_facility == Facility.cross_facility
  end

  def init_current_facility
    raise ActiveRecord::RecordNotFound unless current_facility
  end

  # TODO: refactor existing calls of this definition to use this helper
  def current_cart
    acting_user.cart(session_user)
  end

  def init_current_account
    @account = Account.find(params[:account_id] || params[:id])
  end

  def check_acting_as
    raise NUCore::NotPermittedWhileActingAs if acting_as?
  end

  def backend?
    params[:controller].starts_with?("facilit")
  end

  # authorization before_filter for billing actions
  def check_billing_access
    # something has gone wrong,
    # this before_filter shouldn't be run
    raise ActiveRecord::RecordNotFound unless current_facility

    authorize! :manage_billing, current_facility
  end

  # helper for actions in the 'Billing' manager tab
  #
  # Purpose:
  #   used to get facilities normally used to scope down
  #   which order_details / journals are shown within the tables
  #
  # Returns
  #   returns an ActiveRecord::Relation of facilities
  #   which order_details / journals should be limited to
  #   when running a transaction search or working in the billing tab
  #
  # depends heavily on value of current_facility
  def manageable_facilities
    @manageable_facilities =
      case
      when current_facility.blank?
        session_user.manageable_facilities
      when current_facility.cross_facility?
        Facility.alphabetized
      else
        Facility.where(id: current_facility.id)
      end
  end

  # return an ActiveRecord:Relation of facilities where this user has a role (ie is staff or higher)
  # Administrator and Global Billing Administrator get a relation of all facilities
  def operable_facilities
    @operable_facilities ||= (session_user.blank? ? [] : session_user.operable_facilities)
  end

  # BCSEC legacy method. Kept to give us ability to override devises #current_user.
  def session_user
    @session_user ||= current_user
  rescue
    nil
  end

  def acting_user
    @acting_user ||= User.find_by(id: session[:acting_user_id]) || session_user
  end

  def acting_as?
    return false if session_user.nil?
    acting_user.object_id != session_user.object_id
  end

  # Global exception handlers
  rescue_from ActiveRecord::RecordNotFound do |exception|
    Rails.logger.debug("#{exception.message}: #{exception.backtrace.join("\n")}") unless Rails.env.production?
    render_404(exception)
  end

  rescue_from ActionController::RoutingError do |exception|
    Rails.logger.debug("#{exception.message}: #{exception.backtrace.join("\n")}") unless Rails.env.production?
    render_404(exception)
  end

  def render_404(_exception)
    # Add html fallback in case the 404 is a PDF or XML so the view can be found
    render "/404", status: 404, layout: "application", formats: formats_with_html_fallback
  end

  rescue_from NUCore::PermissionDenied, CanCan::AccessDenied, with: :render_403
  def render_403(_exception)
    # if current_user is nil, the user should be redirected to login
    if current_user
      render "/403", status: 403, layout: "application", formats: formats_with_html_fallback
    else
      store_location_for(:user, request.fullpath)
      redirect_to new_user_session_path
    end
  end

  rescue_from NUCore::NotPermittedWhileActingAs, with: :render_acting_error
  def render_acting_error
    render "/acting_error", status: 403, layout: "application", formats: formats_with_html_fallback
  end

  def after_sign_out_path_for(_)
    if current_facility.present?
      facility_path(current_facility)
    else
      super
    end
  end

  #
  # Will go to the facility version of the path if you are within a facility,
  # otherwise go to the normal version. Useful for sharing views.
  # E.g.:
  # If you are in a facility, open_or_facility_path('account', @account) will link
  # to facility_account_path(current_facility, @account), while if you are not, it will
  # just go to account_path(@account).
  def open_or_facility_path(path, *options)
    path += "_path"
    if current_facility
      path = "facility_" + path
      send(path, current_facility, *options)
    else
      send(path, *options)
    end
  end

  def store_fullpath_in_session
    store_location_for(:user, request.fullpath) unless current_user
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, ability_resource, self)
  end

  private

  #
  # The +Ability+ class, which is used by cancan for authorization,
  # determines authorization by user and some resource. That resource
  # is returned by this method. By default it is #current_facility.
  # Override here to easily change the resource.
  def ability_resource
    current_facility
  end

  def empty_params
    ActionController::Parameters.new
  end

  def with_dropped_params(&block)
    QuietStrongParams.with_dropped_params(&block)
  end

  def formats_with_html_fallback
    request.formats.map(&:symbol) + [:html]
  end

end
