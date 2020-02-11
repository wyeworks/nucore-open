# frozen_string_literal: true

class AddToOrderForm

  include ActiveModel::Model
  include TextHelpers::Translation

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
    @current_facility = original_order.facility
    @account_id = original_order.account_id
    @quantity = 1
    @duration = 1
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
    @merge_order = if products.any?(&:mergeable?)
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
    if order_detail.valid_for_purchase?
      order_detail.ordered_at = order_detail.manual_fulfilled_at_time || Time.current
    end
  end

end
