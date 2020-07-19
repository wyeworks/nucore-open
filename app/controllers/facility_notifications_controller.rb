# frozen_string_literal: true

class FacilityNotificationsController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as

  before_action :init_current_facility
  before_action :check_billing_access

  before_action :check_review_period

  layout "two_column_head"

  def initialize
    @active_tab = "admin_billing"
    super
  end

  def check_review_period
    raise ActionController::RoutingError.new("Notifications disabled with a zero-day review period") unless SettingsHelper.has_review_period?
  end

  # GET /facilities/notifications
  def index
    order_details = OrderDetail.need_notification.for_facility(current_facility)

    @search_form = TransactionSearch::SearchForm.new(params[:search])
    @search = TransactionSearch::Searcher.billing_search(order_details, @search_form, include_facilities: current_facility.cross_facility?)
    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details

    @order_detail_action = :send_notifications
  end

  # POST /facilities/notifications/send
  def send_notifications
    if params[:order_detail_ids].nil? || params[:order_detail_ids].empty?
      flash[:error] = I18n.t "controllers.facility_notifications.no_selection"
      redirect_to action: :index
      return
    end

    sender = NotificationSender.new(current_facility, params)

    if sender.perform
      flash[:notice] = send_notification_success_message(sender)
      sender.order_details.each do |order_detail|
        LogEvent.log(order_detail, :notify, current_user)
      end
    else
      flash[:error] = I18n.t("controllers.facility_notifications.errors_html", errors: sender.errors.join("<br/>")).html_safe
    end
    @accounts_to_notify = sender.account_ids_to_notify
    @errors = sender.errors

    redirect_to action: :index
  end

  # GET /facilities/notifications/in_review
  def in_review
    order_details = OrderDetail.in_review.for_facility(current_facility)

    @search_form = TransactionSearch::SearchForm.new(params[:search])
    @search = TransactionSearch::Searcher.billing_search(order_details, @search_form, include_facilities: current_facility.cross_facility?)
    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details.reorder(:reviewed_at)

    @order_detail_action = :mark_as_reviewed
    @extra_date_column = :reviewed_at
  end

  # GET /facilities/notifications/in_review/mark
  def mark_as_reviewed
    if params[:order_detail_ids].nil? || params[:order_detail_ids].empty?
      flash[:error] = I18n.t "controllers.facility_notifications.no_selection"
    else
      @errors = []
      @order_details_updated = []
      params[:order_detail_ids].each do |order_detail_id|
        begin
          od = OrderDetail.for_facility(current_facility).readonly(false).find(order_detail_id)
          od.reviewed_at = Time.zone.now
          od.save!
          LogEvent.log(od, :review, current_user)
          @order_details_updated << od
        rescue => e
          logger.error(e.message)
          @errors << order_detail_id
        end
      end
      flash[:notice] = I18n.t("controllers.facility_notifications.mark_as_reviewed.success") if @order_details_updated.any?
      flash[:error] = I18n.t("controllers.facility_notifications.mark_as_reviewed.errors", errors: @errors.join(", ")) if @errors.any?
    end
    redirect_to action: :in_review
  end

  private

  def send_notification_success_message(sender)
    if sender.accounts_notified_size > 10
      I18n.t("controllers.facility_notifications.send_notifications.success_count", accounts: sender.accounts_notified_size)
    else
      I18n.t("controllers.facility_notifications.send_notifications.success_html", accounts: sender.accounts_notified.map(&:account_list_item).join("<br/>")).html_safe
    end
  end

end
