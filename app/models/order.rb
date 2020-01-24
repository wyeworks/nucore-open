# frozen_string_literal: true

class Order < ApplicationRecord

  belongs_to :user
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by
  belongs_to :merge_order, class_name: "Order", foreign_key: :merge_with_order_id
  belongs_to :account
  belongs_to :facility
  belongs_to :order_import
  has_many   :order_details, dependent: :destroy

  validates_presence_of :user_id, :created_by

  after_save :update_order_detail_accounts, if: :saved_change_to_account_id?

  scope :for_user, ->(user) { where(user_id: user.id, state: "purchased").where.not(ordered_at: nil) }

  delegate :order_notification_recipient, to: :facility

  def self.created_by_user(user)
    where(created_by: user.id)
  end

  def self.carts
    where.not(state: :purchased).where(merge_with_order_id: nil)
  end

  def self.for_facility(facility)
    facility.cross_facility? ? all : where(facility_id: facility.id)
  end

  attr_accessor :being_purchased_by_admin

  include AASM

  aasm column: :state do
    state :new, initial: true
    state :validated
    state :purchased, before_enter: :set_order_details_ordered_at

    event :invalidate do
      transitions to: :new, from: [:new, :validated]
    end

    event :_validate_order do
      transitions to: :validated, from: [:new, :validated], guard: :cart_valid?
    end

    event :purchase, success: :move_order_details_to_default_status do
      transitions to: :purchased, from: :validated
    end

    event :purchase_without_default_status do
      transitions to: :purchased, from: :validated
    end

    event :clear do
      transitions to: :new, from: [:new, :validated], guard: :clear_cart?
    end
  end

  # In older versions of AASM, a guard condition failing would not raise an error.
  # This is to maintain the previous API of simply returning false
  def validate_order!
    _validate_order!
  rescue AASM::InvalidTransition => e
    false
  end

  [:total, :cost, :subsidy, :estimated_total, :estimated_cost, :estimated_subsidy].each do |method_name|
    define_method(method_name) { order_details.non_canceled.map(&method_name).compact.sum }
  end

  def in_cart?
    !purchased?
  end

  def move_order_details_to_default_status
    order_details.each(&:set_default_status!)
  end

  def cart_valid?
    has_details? && has_valid_payment? && order_details.all? { |od| od.being_purchased_by_admin = @being_purchased_by_admin; od.valid_for_purchase? }
  end

  def has_valid_payment?
    account.present? && # order has account
      order_details.all? { |od| od.account_id == account_id } && # order detail accounts match order account
      facility.can_pay_with_account?(account) &&               # payment is accepted by facility
      account.can_be_used_by?(user) &&                         # user can pay with account
      account.active?                                          # account is active/valid
  end

  def has_details?
    order_details.count > 0
  end

  def to_be_merged?
    merge_with_order_id.present?
  end

  def clear_cart?
    order_details.destroy_all
    self.facility = nil
    self.account = nil
    save
  end

  def set_order_details_ordered_at
    self.order_details_ordered_at = Time.current
  end
  #####
  # END acts_as_state_machine

  def add(product, quantity = 1, attributes = {})
    adder = Orders::ItemAdder.new(self)
    ods = adder.add(product, quantity, attributes)

    ods.each(&:assign_estimated_price!)
    ods
  end

  def order_details_ordered_at=(datetime)
    order_details.each { |od| od.ordered_at ||= datetime }
  end

  def initial_ordered_at
    order_details.map(&:ordered_at).min
  end

  ## TODO: this doesn't pass errors up to the caller.. does it need to?
  def update_details(order_detail_updates)
    order_details = self.order_details.find(order_detail_updates.keys)
    order_details.each do |order_detail|
      updates = order_detail_updates[order_detail.id]
      # reset quantity (if present)
      quantity = updates[:quantity].present? ? updates[:quantity].to_i : order_detail.quantity

      # if quantity isn't there or is 0 (and not bundled), destroy and skip
      if quantity == 0 && !order_detail.bundled?
        order_detail.destroy
        next
      end

      unless order_detail.update_attributes(updates)
        logger.debug "errors on #{order_detail.id}"
        order_detail.errors.each do |attr, error|
          logger.debug "#{attr} #{error}"
          errors.add attr, error
        end
        next
      end

      order_detail.assign_estimated_price if order_detail.cost_estimated?
      order_detail.save
    end

    errors.empty?
  end

  def max_group_id
    order_details.maximum(:group_id).to_i + 1
  end

  # Group into chunks by the group_id so bundles stick together. If group_id is
  # nil, it is not a bundle, so it should get its own chunk.
  def grouped_order_details
    sorted_order_details = order_details.sort_by(&:safe_group_id)
    sorted_order_details.slice_when do |before, after|
      before.group_id.nil? || before.group_id != after.group_id
    end
  end

  def has_subsidies?
    order_details.any?(&:has_subsidies?)
  end

  def only_reservation
    order_details.size == 1 && order_details.first.reservation
  end

  def any_details_estimated?
    order_details.any?(&:cost_estimated?)
  end

  # If user_id doesn't match created_by, that means it was ordered on behalf of
  def ordered_on_behalf_of?
    user_id != created_by
  end

  private

  # If we update the account of the order, update the account of
  # each of the child order_details
  def update_order_detail_accounts
    order_details.each do |od|
      od.account = account
      od.save!
    end
  end

end
