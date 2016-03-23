class Order < ActiveRecord::Base

  belongs_to :user
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by
  belongs_to :merge_order, class_name: "Order", foreign_key: :merge_with_order_id
  belongs_to :account
  belongs_to :facility
  belongs_to :order_import
  has_many   :order_details, dependent: :destroy

  validates_presence_of :user_id, :created_by

  after_save :update_order_detail_accounts, if: :account_id_changed?

  scope :for_user, ->(user) { { conditions: ["user_id = ? AND ordered_at IS NOT NULL AND state = ?", user.id, "purchased"] } }

  def self.created_by_user(user)
    where(created_by: user.id)
  end

  def self.carts
    where(ordered_at: nil)
  end

  def self.for_facility(facility)
    facility.cross_facility? ? scoped : where(facility_id: facility.id)
  end

  def self.recent
    where("orders.ordered_at > ?", Time.zone.now - 1.year)
  end

  attr_accessor :being_purchased_by_admin

  # BEGIN acts_as_state_machhine
  include AASM

  aasm_column           :state
  aasm_initial_state    :new
  aasm_state            :new
  aasm_state            :validated
  aasm_state            :purchased

  aasm_event :invalidate do
    transitions to: :new, from: [:new, :validated]
  end

  aasm_event :validate_order do
    transitions to: :validated, from: [:new, :validated], guard: :cart_valid?
  end

  aasm_event :purchase, success: :move_order_details_to_default_status do
    transitions to: :purchased, from: :validated, guard: :place_order?
  end

  aasm_event :clear do
    transitions to: :new, from: [:new, :validated], guard: :clear_cart?
  end

  [:total, :cost, :subsidy, :estimated_total, :estimated_cost, :estimated_subsidy].each do |method_name|
    define_method(method_name) { total_cost method_name }
  end

  def in_cart?
    !ordered_at?
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
      account.is_active?                                       # account is active/valid
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

  # set the ordered time and send emails
  def place_order?
    # set the ordered_at date
    self.ordered_at ||= Time.zone.now
    save
  end
  #####
  # END acts_as_state_machine

  def instrument_order_details
    order_details.find(:all, joins: "LEFT JOIN products p ON p.id = order_details.product_id", conditions: { "p.type" => "Instrument" })
  end

  def service_order_details
    order_details.find(:all, joins: "LEFT JOIN products p ON p.id = order_details.product_id", conditions: { "p.type" => "Service" })
  end

  def item_order_details
    order_details.find(:all, joins: "LEFT JOIN products p ON p.id = order_details.product_id", conditions: { "p.type" => "Item" })
  end

  def add(product, quantity = 1, attributes = {})
    adder = Orders::ItemAdder.new(self)
    ods = adder.add(product, quantity, attributes)

    ods.each(&:assign_estimated_price!)
    ods
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

  def can_backdate_order_details?
    ordered_at <= Time.zone.now
  end

  def backdate_order_details!(update_by, order_status)
    # can accept either an order status or an id
    order_status = order_status.is_a?(OrderStatus) ? order_status : OrderStatus.find(order_status)

    order_details.each do |od|
      if order_status.root == OrderStatus.complete.first
        od.backdate_to_complete!(ordered_at)
      else
        od.update_order_status!(update_by, order_status, admin: true)
      end
    end
  end

  def complete_past_reservations!
    order_details.select { |od| od.reservation && od.reservation.reserve_end_at < Time.zone.now }.each do |od|
      od.backdate_to_complete! od.reservation.reserve_end_at
    end
  end

  def max_group_id
    order_details.maximum(:group_id).to_i + 1
  end

  def has_subsidies?
    order_details.any?(&:has_subsidies?)
  end

  def only_reservation
    order_details.size == 1 && order_details.first.reservation
  end

  def any_details_estimated?
    order_details.any? &:cost_estimated?
  end

  # was originally used in OrdersController#add
  # def auto_assign_account!(product)
  # return if self.account

  # accounts=user.accounts.active.for_facility(product.facility)

  # if accounts.size > 0
  # orders=user.orders.delete_if{|o| o.ordered_at.nil? || o == self || !accounts.include?(o.account) }

  # if orders.blank?
  # accounts.each{|acct| self.account=acct and break if acct.validate_against_product(product, user).nil? }
  # else
  ## last useable account used to place an order
  # orders.sort{|x,y| y.ordered_at <=> x.ordered_at}.each do |order|
  # acct=order.account
  # self.account=acct and break if accounts.include?(acct) && acct.validate_against_product(product, user).nil?
  # end
  # end
  # end

  # raise I18n.t('models.order.auto_assign_account', :product_name => product.name) if self.account.nil?
  # end

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

  def total_cost(order_detail_method)
    cost = 0
    order_details.each do |od|
      od_cost = od.method(order_detail_method.to_sym).call
      cost += od_cost if od_cost
    end
    cost
  end

end
