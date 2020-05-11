# frozen_string_literal: true

class AddToOrderForm

  include ActiveModel::Model
  include TextHelpers::Translation
  include DateHelper

  attr_reader :original_order, :current_facility
  attr_accessor :quantity, :product_id, :order_status_id, :note, :duration, :created_by, :fulfilled_at, :account_id, :reference_id
  attr_accessor :error_message

  validates :account_id, presence: true
  validates :account, presence: true, if: :account_id
  validates :product_id, presence: true
  validates :order_status_id, presence: true
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :reference_id, length: { minimum: 0, maximum: 30 }, allow_blank: true

  def initialize(original_order)
    @original_order = original_order
    set_default_values
  end

  def save
    raise(ActiveRecord::RecordInvalid, self) unless valid?

    add_to_order!
    true
  rescue AASM::InvalidTransition
    @error_message = text("invalid_status", product: product, status: order_status)
    false
  rescue ActiveRecord::RecordInvalid => e
    @error_message = e.record.errors.full_messages.to_sentence
    false
  rescue => e
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    @error_message = text("error", product: product.name)
    false
  end

  def notifications?
    @notifications
  end

  def success_message
    text("success", product: product.name)
  end

  def notifications_message
    text("notices", product: product.name)
  end

  def product
    @product ||= current_facility.products.find(product_id)
  end

  # Will be blank if the account_id is suspended or expired. That should only happen
  # if someone is hacking the form since they should be excluded from being available
  # in the dropdown.
  def account
    @account ||= available_accounts.to_a.find { |a| a.id.to_s == account_id.to_s }
  end

  def available_accounts
    AvailableAccountsFinder.new(original_order.user, current_facility)
  end

  # We're using the ordered_at of the order details to determine if additional OrderDetails
  # have been added to the order. We find the most recently added order that does not
  # match the original order's ordered_at and use that for our basis for defaults.
  # There is an edge case: 1) Upload an order via bulk upload. 2) Add on to that order
  # here. 3) Upload again via bulk upload matching the ordered_at of the original.
  # In that situation, we will return the results of #2.
  def previously_added_order_detail
    return @previously_added_order_detail if defined?(@previously_added_order_detail)

    # We are ordering by created_at rather than ID because it is possible in Oracle
    # for the IDs to be assigned out of insert order due to the way it caches sequence values.
    # https://stackoverflow.com/questions/4866959/oracle-rac-and-sequences
    order_details = @original_order.order_details.order(:created_at)
    original_order_detail = order_details.first

    @previously_added_order_detail = order_details.reverse.find { |od| od.ordered_at != original_order_detail.ordered_at }
  end

  protected

  def translation_scope
    "forms.add_to_order_form"
  end

  private

  def add_to_order!
    OrderDetail.transaction do
      merge_order.add(product, quantity, params).each do |order_detail|
        backdate(order_detail)

        order_detail.set_default_status!
        order_detail.change_status!(order_status) if order_status.present?

        if merge_order.to_be_merged? && !order_detail.valid_for_purchase?
          @notifications = true
          MergeNotification.create_for!(created_by, order_detail)
        end
      end
    end
  end

  def set_default_values
    @current_facility = original_order.facility
    @account_id = original_order.account_id
    @quantity = 1
    @duration = 1

    if previously_added_to?
      # This is a string so it displays on the form correctly.
      # It may be nil if the order is not complete
      @fulfilled_at = format_usa_date(previously_added_order_detail.fulfilled_at)
      @order_status_id = previously_added_order_detail.order_status_id
    else
      @fulfilled_at = nil
      @order_status_id = OrderStatus.new_status.id
    end
  end

  def previously_added_to?
    previously_added_order_detail.present?
  end

  def params
    {
      note: note.presence,
      duration: duration,
      created_by: created_by.id,
      account: account,
      reference_id: reference_id,
    }
  end

  def order_status
    @order_status ||= OrderStatus.for_facility(current_facility).find(order_status_id) if order_status_id
  end

  def merge_order
    return @merge_order if defined?(@merge_order)

    products = product.is_a?(Bundle) ? product.products : [product]
    @merge_order = if products.any?(&:requires_merge?)
                     Order.create!(
                       merge_with_order_id: original_order.id,
                       facility_id: original_order.facility_id,
                       account_id: account_id,
                       user_id: original_order.user_id,
                       created_by: created_by.id,
                     )
                   else
                     original_order
                   end
  end

  def backdate(order_detail)
    # `fulfilled_at` is a string and might get misinterpretted as DD/MM instead of MM/DD.
    # `manual_fulfilled_at` already handles the proper string parsing so we can use
    # it instead of duplicating the parsing effort.
    order_detail.manual_fulfilled_at = fulfilled_at
    # If we are a merge order (i.e. requires more action like uploading an order form),
    # we do not want to set the ordered_at just yet. It will be set after the issues have
    # been resolved.
    if merge_order == original_order
      order_detail.ordered_at = order_detail.manual_fulfilled_at_time || Time.current
    end
  end

end
