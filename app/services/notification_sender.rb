# frozen_string_literal: true

class NotificationSender

  attr_reader :errors, :current_facility

  def initialize(current_facility, params)
    @current_facility = current_facility
    @order_detail_ids = params[:order_detail_ids]
    @notify_zero_dollar_orders = ActiveModel::Type::Boolean.new.cast(params[:notify_zero_dollar_orders])
  end

  def account_ids_to_notify
    return @account_ids_to_notify if @account_ids_to_notify.present?

    to_notify = order_details
    to_notify = to_notify.none unless SettingsHelper.has_review_period?
    to_notify = to_notify.where("actual_cost > 0") unless @notify_zero_dollar_orders
    @account_ids_to_notify = to_notify.distinct.pluck(:account_id)
  end

  def perform
    @errors = []
    find_missing_order_details
    return if @errors.any?

    OrderDetail.transaction do
      account_ids_to_notify # needs to be memoized before order_details get reviewed
      mark_order_details_as_reviewed
      auto_dispute_order_details
      notify_accounts
    end
  end

  def accounts_notified_size
    account_ids_to_notify.count
  end

  def accounts_notified
    Account.where_ids_in(account_ids_to_notify)
  end

  def order_details
    @order_details ||= OrderDetail.for_facility(current_facility)
                                  .need_notification
                                  .where_ids_in(@order_detail_ids)
                                  .includes(:product, :order, :price_policy, :reservation)
  end

  # If desired, override this method to automatically dispute order details,
  # during NotificationSender#perform. As an example, UMass overrides this
  # method in UmassCorum::NotificationSenderExtension
  def auto_dispute_order_details
    nil
  end

  private

  def find_missing_order_details
    order_details_not_found = @order_detail_ids.map(&:to_i) - order_details.pluck(:id)

    order_details_not_found.each do |order_detail_id|
      @errors << I18n.t("controllers.facility_notifications.send_notifications.order_error", order_detail_id: order_detail_id)
    end
  end

  def mark_order_details_as_reviewed
    order_details.each do |order_detail|
      order_detail.update(reviewed_at: reviewed_at)
    end
  end

  def reviewed_at
    @reviewed_at ||= Time.zone.now + Settings.billing.review_period
  end

  def notify_accounts
    accounts_by_user.each do |user, accounts|
      Notifier.review_orders(
        user:, accounts:, facility: current_facility,
      ).deliver_later
    end
  end

  ##
  # This builds a Hash of account Arrays, keyed by the user. The
  # users are the administrators (owners and business
  # administrators) of the given accounts.
  def accounts_by_user
    account_ids_to_notify.each_with_object({}) do |account_id, notifications|
      account = Account.find(account_id)
      account.administrators.each do |administrator|
        notifications[administrator] ||= []
        notifications[administrator] << account
      end
    end
  end

end
