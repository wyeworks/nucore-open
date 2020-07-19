# frozen_string_literal: true

class NotificationSender

  attr_reader :errors, :current_facility

  def initialize(current_facility, params)
    @current_facility = current_facility
    @order_detail_ids = params[:order_detail_ids]
    @notify_zero_dollar_orders = ActiveModel::Type::Boolean.new.cast(params[:notify_zero_dollar_orders])
  end

  def account_ids_to_notify
    to_notify = order_details
    to_notify = to_notify.none unless SettingsHelper.has_review_period?
    to_notify = to_notify.where("actual_cost > 0") unless @notify_zero_dollar_orders
    @account_ids_to_notify ||= to_notify.distinct.pluck(:account_id)
  end

  def perform
    @errors = []
    find_missing_order_details
    return if @errors.any?

    OrderDetail.transaction do
      account_ids_to_notify # needs to be memoized before order_details get reviewed
      mark_order_details_as_reviewed
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

  class AccountNotifier

    def notify_accounts(account_ids_to_notify, facility)
      notifications_hash(account_ids_to_notify).each do |user, accounts|
        Notifier.review_orders(user: user, accounts: accounts, facility: facility).deliver_now
      end
    end

    private

    # This builds a Hash of account Arrays, keyed by the user.
    # The users are the administrators (owners and business administrators)
    # of the given accounts.
    def notifications_hash(account_ids_to_notify)
      account_ids_to_notify.each_with_object({}) do |account_id, notifications|
        account = Account.find(account_id)
        account.administrators.each do |administrator|
          notifications[administrator] ||= []
          notifications[administrator] << account
        end
      end
    end

  end

  def notify_accounts
    AccountNotifier.new.delay.notify_accounts(account_ids_to_notify, current_facility)
  end

end
