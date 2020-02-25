# frozen_string_literal: true

class OrderDetail < ApplicationRecord

  include NUCore::Database::SortHelper
  include TranslationHelper
  include NotificationSubject
  include OrderDetail::Accessorized
  include NUCore::Database::WhereIdsIn

  has_paper_trail

  # Used when ordering to override certain restrictions
  attr_accessor :being_purchased_by_admin

  # Used in the order detail popup to allow reservations and occupancies to
  # enforce additional validations.
  attr_accessor :editing_time_data

  # So you can see what price policy was used in the price estimation
  attr_reader :estimated_price_policy

  attr_accessor :order_status_updated_by

  # These need to be writable for split accounts to work. If they haven't been
  # explicitly written to, they'll be calculated.
  attr_writer :calculated_cost, :calculated_subsidy

  # Used to mark a dispute as resolved
  attr_accessor :resolve_dispute
  before_validation :mark_dispute_resolved, if: :resolve_dispute
  after_validation :reset_dispute

  before_save :clear_statement, if: :account_id_changed?
  before_save :reassign_price, if: :auto_reassign_pricing?
  before_save :update_journal_row_amounts, if: :actual_cost_changed?

  before_save :set_problem_order
  def set_problem_order
    self.problem = problem_description_key.present?
    update_fulfilled_at_on_resolve if time_data.present?
    true # problem might be false; we need the callback chain to continue
  end

  after_save :update_billable_minutes_on_reservation, if: :reservation

  belongs_to :product
  belongs_to :price_policy
  belongs_to :statement, inverse_of: :order_details
  belongs_to :journal
  belongs_to :order, inverse_of: :order_details
  belongs_to :assigned_user, class_name: "User", foreign_key: "assigned_user_id"
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by
  belongs_to :dispute_by, class_name: "User"
  belongs_to :price_changed_by_user, class_name: "User"
  belongs_to :order_status
  belongs_to :account
  belongs_to :bundle, foreign_key: "bundle_product_id"
  belongs_to :canceled_by_user, foreign_key: :canceled_by, class_name: "User"
  belongs_to :problem_resolved_by, class_name: "User"
  has_one    :reservation, inverse_of: :order_detail
  # for some reason, dependent: :delete on reservation isn't working with paranoia, hitting foreign key constraints
  before_destroy { reservation.try(:really_destroy!) }
  has_one    :external_service_receiver, as: :receiver, dependent: :destroy
  has_many   :journal_rows, inverse_of: :order_detail
  has_many   :notifications, as: :subject, dependent: :destroy
  has_many   :stored_files, dependent: :destroy
  has_many   :sample_results_files, -> { sample_result }, class_name: "StoredFile"

  # This is a _temporary_ associaton to make up for the fact that the
  # vestal versions gem is no longer in the project. It's here to
  # allow access to the vestal data.
  # once that data is no longer needed, this line and the
  # associated class can be removed
  has_many   :vestal_versions, as: :versioned

  delegate :edit_url, to: :external_service_receiver, allow_nil: true
  delegate :in_cart?, :facility, :user, to: :order
  delegate :invoice_number, to: :statement, prefix: true
  delegate :journal_date, to: :journal, allow_nil: true
  delegate :ordered_on_behalf_of?, to: :order
  delegate :price_group, to: :price_policy, allow_nil: true
  delegate :reference, to: :journal, prefix: true, allow_nil: true

  def estimated_price_group
    estimated_price_policy.try(:price_group)
  end

  # consider changing in Rails 4 to
  # `has_many :current_journal_rows, -> { where(journal_id: journal_id) }`
  def current_journal_rows
    journal_rows.where(journal_id: journal_id)
  end

  def statement_date
    statement.try(:created_at)
  end

  def journal_or_statement_date
    journal_date || statement_date
  end

  validates_presence_of :product_id, :order_id, :created_by
  validates_numericality_of :quantity, only_integer: true, greater_than_or_equal_to: 1
  validates_numericality_of :actual_cost, greater_than_or_equal_to: 0, if: ->(o) { o.actual_cost_changed? && !o.actual_cost.nil? }
  validates_numericality_of :actual_subsidy, greater_than_or_equal_to: 0, if: ->(o) { o.actual_subsidy_changed? && !o.actual_cost.nil? }
  validates_numericality_of :actual_total, greater_than_or_equal_to: 0, allow_nil: true
  validates_presence_of :dispute_reason, if: :dispute_at
  validates_presence_of :dispute_resolved_at, :dispute_resolved_reason, if: proc { dispute_resolved_reason.present? || dispute_resolved_at.present? }
  # only do this validation if it hasn't been ordered yet. Update errors caused by notification sending
  # were being triggered on orders where the orderer had been removed from the account.
  validate :account_usable_by_order_owner?, if: ->(order_detail) { order_detail.account_id_changed? || order_detail.order.nil? || order_detail.ordered_at.blank? }
  validates_length_of :note, maximum: 1000, allow_blank: true, allow_nil: true
  validate :valid_manual_fulfilled_at
  validates :price_change_reason, presence: true, length: { minimum: 10, allow_blank: true }, if: :pricing_note_required?

  def actual_costs_match_calculated?
    dup_od = dup
    dup_od.time_data = time_data.dup
    dup_od.assign_price_policy

    dup_od.actual_cost == actual_cost && dup_od.actual_subsidy == actual_subsidy
  end

  ## TODO validate assigned_user is a member of the product's facility
  ## TODO validate order status is global or a member of the product's facility
  ## TODO validate which fields can be edited for which states

  scope :batch_updatable, -> { where(dispute_at: nil, state: %w(new inprocess)) }
  scope :new_or_inprocess, -> { purchased.where(state: %w(new inprocess)) }
  scope :non_canceled, -> { where.not(state: "canceled") }

  def self.for_facility(facility)
    for_facility_id(facility.id)
  end

  def self.for_facility_id(facility_id = nil)
    if facility_id.present?
      joins(:order).where(orders: { facility_id: facility_id })
    else
      all
    end
  end

  scope :recent, -> { where("ordered_at > ?", 1.year.ago) }

  def self.in_dispute
    where("dispute_at IS NOT NULL")
      .where(dispute_resolved_at: nil)
      .where("order_details.state != ?", "canceled")
  end

  scope :purchased_active_reservations, -> { new_or_inprocess.joins(:reservation).merge(Reservation.not_canceled) }

  scope :with_price_policy, -> { where.not(price_policy_id: nil) }

  scope :not_disputed, lambda {
    where(dispute_at: nil).or(where.not(dispute_resolved_at: nil))
  }

  scope :need_notification, lambda {
    joins(:product)
      .where(state: "complete")
      .where(reviewed_at: nil)
      .with_price_policy
      .not_disputed
      .where(problem: false)
  }

  def self.all_movable
    ordered_at
      .unreconciled
      .where(journal_id: nil)

  end

  scope :in_review, lambda {
    joins(:order)
      .where(state: "complete")
      .where("order_details.reviewed_at > ?", Time.current)
      .not_disputed
  }

  def self.recently_reviewed
    where(state: %w(complete reconciled))
      .where("order_details.reviewed_at < ?", Time.zone.now)
      .not_disputed
      .order(:reviewed_at).reverse_order
  end

  def self.reassign_account!(account, order_details)
    OrderDetail.transaction do
      order_details.each do |order_detail|
        order_detail.account = account
        order_detail.save!
      end
    end
  end

  def self.problem_orders
    where(problem: true)
  end

  def self.joins_relay
    joins("INNER JOIN relays ON relays.instrument_id = products.id")
  end

  def self.unreconciled
    where.not(state: "reconciled")
  end

  def self.with_actual_costs
    where.not(actual_cost: nil)
  end

  def self.with_estimated_costs
    where.not(estimated_cost: nil)
  end

  def can_be_viewed_by?(user)
    order.user_id == user.id || account.owner_user.id == user.id || account.business_admins.any? { |au| au.user_id == user.id }
  end

  scope :need_statement, lambda { |facility|
    complete
      .for_facility(facility)
      .joins(:product, :account)
      .where(problem: false)
      .where("reviewed_at <= ?", Time.current)
      .where(statement_id: nil)
      .with_price_policy
      .where("accounts.type" => Account.config.statement_account_types)
      .not_disputed
  }

  scope :need_journal, lambda { # TODO: share common pieces with :need_statement scope
    complete
      .joins(:product, :account)
      .where(problem: false)
      .where("reviewed_at <= ?", Time.current)
      .where("accounts.type" => Account.config.journal_account_types)
      .where(journal_id: nil)
      .with_price_policy
      .not_disputed
  }

  # these depend on a join with accounts, as in .need_journal above
  scope :unexpired_account, -> { where("accounts.expires_at >= order_details.fulfilled_at") }
  scope :expired_account, -> { where("accounts.expires_at < order_details.fulfilled_at") }

  scope :statemented, lambda { |facility|
    joins(:order)
      .where(orders: { facility_id: facility.id })
      .where.not(statement_id: nil)
  }

  # Supports single type or an array of product types
  scope :for_product_type, ->(product_type) { joins(:product).where(products: { type: product_type }) }
  scope :item_and_service_orders, -> { for_product_type(["Item", "Service", "TimedService"]) }
  scope :reservations, -> { for_product_type("Instrument") }

  scope :purchased, -> { joins(:order).merge(Order.purchased) }
  scope :ordered_at, -> { where.not(ordered_at: nil) }

  scope :with_reservation, -> { purchased.joins(:reservation).order("reservations.reserve_start_at DESC") }
  scope :with_upcoming_reservation, lambda {
    new_or_inprocess
      .with_reservation
      .where(reservations: { actual_start_at: nil })
      .merge(Reservation.ends_in_the_future)
  }
  scope :with_in_progress_reservation, -> { new_or_inprocess.with_reservation.merge(Reservation.relay_in_progress) }

  scope :for_accounts, ->(accounts) { where("order_details.account_id in (?)", accounts) unless accounts.nil? || accounts.empty? }
  scope :for_facilities, ->(facilities) { joins(:order).where("orders.facility_id in (?)", facilities) unless facilities.nil? || facilities.empty? }
  scope :for_products, ->(products) { where("order_details.product_id in (?)", products) unless products.blank? }
  scope :for_users, ->(user_ids) { joins(:order).where(orders: { user_id: user_ids }) unless user_ids.blank? }
  scope :for_owners, lambda { |owners|
    return if owners.blank?
    joins(account: :account_users)
      .where(account_users: { user_role: AccountUser::ACCOUNT_OWNER,
                              user_id: owners })
  }
  scope :for_order_statuses, ->(statuses) { where("order_details.order_status_id in (?)", statuses) unless statuses.nil? || statuses.empty? }
  scope :joins_assigned_users, -> { joins("LEFT OUTER JOIN users assigned_users ON assigned_users.id = order_details.assigned_user_id") }

  scope :fulfilled_in_date_range, lambda { |start_date, end_date|
    action_in_date_range :fulfilled_at, start_date, end_date
  }

  scope :action_in_date_range, lambda { |action, start_date, end_date|
    valid = TransactionSearch::DateRangeSearcher::FIELDS.map(&:to_sym) + [:journal_date]
    raise ArgumentError.new("Invalid action: #{action}. Must be one of: #{valid}") unless valid.include? action.to_sym
    logger.debug("searching #{action} between #{start_date} and #{end_date}")
    search = all

    return journaled_or_statemented_in_date_range(start_date, end_date) if action.to_sym == :journal_or_statement_date
    search = search.joins(:journal) if action.to_sym == :journal_date

    # If we're searching on fulfilled_at, ignore any order details that don't have a fulfilled date
    search = search.where("#{action} IS NOT NULL") if [:reconciled_at, :fulfilled_at].include?(action.to_sym)

    search = search.where("#{action} >= ?", start_date.beginning_of_day) if start_date
    search = search.where("#{action} <= ?", end_date.end_of_day) if end_date
    search
  }

  scope :ordered_by_action_date, lambda { |action|
    action = "COALESCE(journal_date, in_range_statements.created_at)" if action.to_sym == :journal_or_statement_date
    order_by_desc_nulls_first(action)
  }

  def self.journaled_or_statemented_in_date_range(start_date, end_date)
    search = joins("LEFT JOIN journals ON journals.id = order_details.journal_id")
             .joins("LEFT JOIN statements in_range_statements ON in_range_statements.id = order_details.statement_id")

    journal_query = ["journal_id IS NOT NULL"]
    journal_query << "journals.journal_date >= :start_date" if start_date
    journal_query << "journals.journal_date < :end_date" if end_date

    statement_query = ["statement_id IS NOT NULL"]
    statement_query << "in_range_statements.created_at >= :start_date" if start_date
    statement_query << "in_range_statements.created_at < :end_date" if end_date

    search.where(
      "(#{journal_query.join(' AND ')}) OR (#{statement_query.join(' AND ')})",
      start_date: start_date.try(:beginning_of_day),
      end_date: end_date.try(:end_of_day),
    )
  end

  def self.ordered_or_reserved_in_range(start_date, end_date)
    start_date = start_date.beginning_of_day if start_date
    end_date = end_date.end_of_day if end_date

    query = joins("LEFT JOIN reservations ON reservations.order_detail_id = order_details.id")
    # If there is a reservation, query on the reservation time, if there's not a reservation (i.e. the left join ends up with a null reservation)
    # use the ordered at time
    if start_date && end_date
      sql = "(reservations.id IS NULL AND order_details.ordered_at > :start AND order_details.ordered_at < :end) OR (reservations.id IS NOT NULL AND reservations.reserve_start_at > :start AND reservations.reserve_start_at < :end)"
    elsif start_date
      sql = "(reservations.id IS NULL AND order_details.ordered_at > :start) OR (reservations.id IS NOT NULL AND reservations.reserve_start_at > :start)"
    elsif end_date
      sql = "(reservations.id IS NULL AND order_details.ordered_at < :end) OR (reservations.id IS NOT NULL AND reservations.reserve_start_at < :end)"
    end

    query.where(sql, start: start_date, end: end_date)
  end

  include AASM

  CANCELABLE_STATES = [:new, :inprocess, :complete].freeze
  aasm column: :state do
    state :new, initial: true
    state :inprocess
    state :complete, enter: :make_complete
    state :reconciled, enter: :set_reconciled_at
    state :canceled, enter: :clear_costs

    event :to_new do
      transitions to: :new, from: :inprocess
    end

    event :to_inprocess do
      transitions to: :inprocess, from: :new
    end

    event :to_complete do
      transitions to: :complete, from: [:new, :inprocess], guard: :time_data_completeable?
    end

    event :to_reconciled do
      transitions to: :reconciled, from: :complete, guard: :actual_total
    end

    event :to_canceled do
      transitions to: :canceled, from: CANCELABLE_STATES, guard: :cancelable?
    end
  end

  # block will be called after the transition, but before the save
  def change_status!(new_status, &block)
    new_state = new_status.state_name
    # don't try to change state if it's not a valid state or it's the same as it was before
    send("to_#{new_state}") if OrderDetail.aasm.states.map(&:name).include?(new_state) && new_state != state.to_sym
    # don't try to change status if it's the same as before
    unless new_status == order_status
      self.order_status = new_status
      yield(self) if block
      save!
    end
    true
  end

  # This method is a replacement for change_status! that also will cancel the associated reservation when necessary
  def update_order_status!(updated_by, order_status, options = {}, &block)
    @order_status_updated_by = updated_by
    options.reverse_merge!(admin: false, apply_cancel_fee: false)

    if reservation && order_status.root_canceled?
      cancel_reservation(updated_by,
                         order_status: order_status,
                         admin: options[:admin],
                         admin_with_cancel_fee: options[:apply_cancel_fee])
    else
      if order_status.root_canceled?
        clear_statement
        assign_attributes(canceled_by_user: updated_by, canceled_at: Time.current)
      end
      change_status! order_status, &block
    end
  end

  # OrderDetail#complete! should be used to complete an OrderDetail instead of
  # OrderDetail#to_complete
  def complete!
    change_status!(OrderStatus.complete)
  end

  def backdate_to_complete!(event_time = Time.zone.now)
    # if we're setting it to compete, automatically set the actuals for a reservation
    if reservation
      raise NUCore::PurchaseException.new(t_model_error(Reservation, "cannot_be_completed_in_future")) if reservation.reserve_end_at > event_time
      reservation.assign_actuals_off_reserve unless reservation.product.reservation_only?
      reservation.save!
    end
    change_status!(OrderStatus.complete) do |od|
      od.fulfilled_at = event_time
      od.assign_price_policy
    end
  end

  def set_default_status!
    change_status! product.initial_order_status
  end

  def save_as_user(user)
    @being_purchased_by_admin = user.operator_of?(product.facility)
    save
  end

  def save_as_user!(user)
    raise ActiveRecord::RecordInvalid.new(self) unless save_as_user(user)
  end

  def state_is_cancelable?
    CANCELABLE_STATES.include?(state.to_sym)
  end

  def has_uncanceled_reservation?
    reservation.present? && !canceled_at?
  end

  def cancelable?
    # can't cancel if the reservation isn't already canceled or if this OD has been added to a journal
    state_is_cancelable? && journal.nil? && !has_uncanceled_reservation?
  end

  def pending?
    order.purchased? && state.in?(%w[new inprocess])
  end

  def cost
    actual_cost || estimated_cost || 0
  end

  def subsidy
    actual_subsidy || estimated_subsidy || 0
  end

  def actual_total
    actual_cost - actual_subsidy if actual_cost && actual_subsidy
  end

  def estimated_total
    estimated_cost - estimated_subsidy if estimated_cost && estimated_subsidy
  end

  def total
    cost - subsidy unless cost.nil? || subsidy.nil?
  end

  def price_groups
    groups = user.price_groups
    groups += account.price_groups if account
    groups.uniq
  end

  # returns true if the associated survey response set has been completed
  def survey_completed?
    external_service_receiver.present?
  end

  def quantity_locked_by_survey?
    survey_completed? && external_service_receiver.manages_quantity?
  end

  def account_usable_by_order_owner?
    return unless order && account_id
    errors.add("account_id", "is not valid for the orderer") unless AccountUser.find_by(user_id: order.user_id, account_id: account_id, deleted_at: nil)
  end

  def customer_account_changeable?
    journal_id.blank? && statement_id.blank? && !canceled?
  end

  def validate_for_purchase
    # can purchase product
    return "The product may not be purchased" unless product.available_for_purchase?

    # payment method is selected
    return "You must select a payment method" if account.nil?

    # payment method is not expired
    return "The account is expired and cannot be used" if account.expires_at < Time.zone.now || account.suspended_at

    # TODO: if chart string, is chart string + account valid
    return I18n.t("not_open", model: account.type_string, scope: "activerecord.errors.models.account") if account.respond_to?(:account_open?) && !account.account_open?(product.account)

    # is the user approved for the product
    return "You are not approved to purchase this #{product.class.name.downcase}" unless product.can_be_used_by?(order.user) || order.created_by_user.can_override_restrictions?(product)

    # are reservation requirements met
    response = validate_reservation
    return response if response

    # are survey requirements met
    response = validate_service_meta
    return response if response

    return nil if product.can_purchase_order_detail? self

    "No assigned price groups allow purchase of this product"
  end

  def valid_for_purchase?
    validate_for_purchase.nil? ? true : false
  end

  def validate_reservation
    return nil unless product.is_a?(Instrument)
    return "Please make a reservation" if reservation.nil?
    reservation.reserved_by_admin = @being_purchased_by_admin
    return "There is a problem with your reservation" unless reservation.valid? && reservation.valid_before_purchase?
  end

  def valid_reservation?
    validate_reservation.nil? ? true : false
  end

  def validate_service_meta
    return nil unless product.is_a?(Service)

    requires_upload = !product.stored_files.template.empty?
    requires_survey = product.active_survey?
    valid_upload    = requires_upload ? validate_uploaded_files : nil
    valid_survey    = requires_survey ? validate_survey         : nil

    if requires_upload && requires_survey && valid_survey && valid_upload
      return "Please complete the online order form or upload an order form"
    elsif requires_upload && requires_survey && (valid_upload || valid_survey)
      return nil
    else
      return valid_upload || valid_survey
    end
  end

  def valid_service_meta?
    validate_service_meta.nil? ? true : false
  end

  def validate_uploaded_files
    templates = product.stored_files.template
    if templates.empty?
      nil # no file templates
    else
      # check for a template result
      results = stored_files.template_result
      "Please upload an order form" if results.empty?
    end
  end

  def validate_survey
    if !product.active_survey?
      nil # no active survey
    elsif product.active_survey? && survey_completed?
      nil # active survey with a completed response set
    else
      # active survey but no response
      "Please complete the online order form"
    end
  end

  def auto_reassign_pricing?
    !@manually_priced && (account_id_changed? || quantity_changed?)
  end

  # Mark the instance as manually priced to prevent the price assignment callback
  # from overwriting the params.
  def manually_priced!
    @manually_priced = true
  end

  def reassign_price
    if cost_estimated?
      assign_estimated_price
    elsif actual_cost
      assign_actual_price
    end
  end

  def update_journal_row_amounts
    JournalRowUpdater.new(self).update
  end

  def assign_estimated_price(date = fulfilled_at || Time.current)
    self.estimated_cost    = nil
    self.estimated_subsidy = nil

    # is account valid for facility
    return if account && !product.facility.can_pay_with_account?(account)

    @estimated_price_policy = product.cheapest_price_policy(self, date)
    assign_estimated_price_from_policy @estimated_price_policy
  end

  def assign_estimated_price!
    assign_estimated_price(Time.current)
    save!
  end

  def assign_estimated_price_from_policy(price_policy)
    return unless price_policy

    costs = price_policy.estimate_cost_and_subsidy_from_order_detail(self)
    return unless costs

    self.estimated_cost    = costs[:cost]
    self.estimated_subsidy = costs[:subsidy]
  end

  def assign_price_policy
    clear_costs

    # is account valid for facility
    return unless product.facility.can_pay_with_account?(account)
    assign_actual_price
  end

  def assign_actual_price
    pp = product.cheapest_price_policy(self, time_for_policy_lookup)
    return unless pp
    costs = pp.calculate_cost_and_subsidy_from_order_detail(self)
    return unless costs
    self.price_policy_id = pp.id
    self.actual_cost     = costs[:cost]
    self.actual_subsidy  = costs[:subsidy]
    pp
  end

  def calculated_cost
    @calculated_cost ||= calculated_costs[:cost]
  end

  def calculated_subsidy
    @calculated_subsidy ||= calculated_costs[:subsidy]
  end

  def calculated_total
    calculated_cost - calculated_subsidy if calculated_cost && calculated_subsidy
  end

  def available_accounts
    Account.for_order_detail(self)
  end

  def order_number
    "#{order_id}-#{id}"
  end
  alias to_s order_number

  def description
    "Order # #{self}"
  end

  # Only used by Journals. Consider pulling into the journal/journal row
  # (NU uses this method in their engines).
  def long_description
    OrderDetailJournalDescriptionPresenter.new(self).long_description
  end

  def cost_estimated?
    price_policy.nil? && estimated_cost && estimated_subsidy && actual_cost.nil? && actual_subsidy.nil? && !canceled?
  end

  def cancel_reservation(canceled_by, canceled_reason: nil, order_status: OrderStatus.canceled, admin: false, admin_with_cancel_fee: false)
    self.canceled_by = canceled_by.id
    self.canceled_reason = canceled_reason

    if admin
      return false unless update_attributes(canceled_at: Time.current)

      if admin_with_cancel_fee
        clear_statement if cancellation_fee == 0
        cancel_with_fee order_status
      else
        clear_statement
        change_status! order_status
      end
    else
      return false unless reservation&.can_cancel?
      # must set canceled_at after calling #can_cancel?
      return false unless update_attributes(canceled_at: Time.current)
      clear_statement if cancellation_fee == 0
      cancel_with_fee order_status
    end
  end

  def cancellation_fee
    CancellationFeeCalculator.new(self).total_cost
  end

  def has_subsidies?
    actual_subsidy.to_f > 0 || estimated_subsidy.to_f > 0
  end

  #
  # If this +OrderDetail+ is #complete? and either:
  #   A) Does not have a +PricePolicy+ or
  #   B) Has a reservation with missing usage information
  # the method will return true, otherwise false
  def problem_order?
    problem
  end

  def can_dispute?
    in_review? && dispute_at.blank?
  end

  def in_dispute?
    dispute_at.present? && dispute_resolved_at.nil? && !canceled?
  end

  def in_review?
    reviewed_at.try(:future?) && !in_dispute?
  end

  def reviewed?
    reviewed_at.try(:past?) && !in_dispute?
  end

  def ready_for_statement?
    reviewed? && statement_id.blank? && Account.config.using_statements?(account.type)
  end

  def ready_for_journal?
    reviewed? && journal_id.blank? && Account.config.using_journal?(account.type) && !reconciled?
  end

  def awaiting_payment?
    statement_id.present? && !reconciled?
  end

  def in_open_journal?
    journal&.open?
  end

  def in_closed_journal?
    journal && !journal.open?
  end

  def can_reconcile?
    complete? && !in_dispute? && account.can_reconcile?(self)
  end

  def can_reconcile_journaled?
    can_reconcile? && in_closed_journal?
  end

  def self.account_unreconciled(facility, account)
    if account.class.using_journal?
      joins(:journal)
        .complete_for_facility_and_account(facility, account)
        .where("journals.is_successful" => true)
    else
      complete_for_facility_and_account(facility, account)
        .where("order_details.statement_id IS NOT NULL")
    end
  end

  def self.complete_for_facility_and_account(facility, account)
    for_facility(facility)
      .where("order_details.account_id" => account.id)
      .where("order_details.state" => "complete")
  end

  #
  # Returns true if this order detail is part of a bundle purchase, false otherwise
  def bundled?
    bundle.present?
  end

  # Useful when sorting so we don't get `nil` to number comparisons
  def safe_group_id
    group_id.to_i
  end

  def to_notice(notification_class, *_args)
    case notification_class.name
    when MergeNotification.name
      notice = "<a href=\"#{facility_order_path(order.facility, order.merge_order)}\">Order ##{order.merge_order.id}</a> needs your attention. A line item was added after purchase and "

      notice += case product
                when Instrument then "has an incomplete reservation."
                when Service then "has an incomplete order form."
                else; "is incomplete."
      end

      notice.html_safe
    else
      ""
    end
  end

  def can_be_assigned_to_account?(account)
    user.accounts.include?(account)
  end

  def removable_from_journal?
    journal.present? && account.class.using_journal? && can_reconcile?
  end

  # This value will be used when marking the order complete. Any other time, it
  # will have no effect. This is to protect `fulfilled_at` from being written
  # to when it shouldn't be. It should be a USA formatted date string.
  def manual_fulfilled_at=(string)
    @manual_fulfilled_at = ValidFulfilledAtDate.new(string)
  end

  def manual_fulfilled_at_time
    @manual_fulfilled_at&.to_time
  end

  def valid_manual_fulfilled_at
    errors.add(:fulfilled_at, @manual_fulfilled_at.error) if @manual_fulfilled_at&.invalid?
  end

  def time_data
    if product.respond_to?(:time_data_field)
      public_send(product.time_data_field) || TimeData::RequiredTimeData.new
    else
      TimeData::NullTimeData.new
    end
  end

  def time_data=(time_data)
    public_send("#{product.time_data_field}=", time_data) if product.respond_to?(:time_data_field)
  end

  def translation_scope
    "activerecord.models.order_detail"
  end

  def problem_description_key
    Array(problem_description_keys).first
  end

  def problem_description_keys
    return [] unless complete?

    time_data_problem_key = time_data.problem_description_key
    price_policy_problem_key = :missing_price_policy if price_policy.blank?

    [time_data_problem_key, price_policy_problem_key].compact
  end

  def requires_but_missing_actuals?
    Array(problem_description_keys).include?(:missing_actuals)
  end

  def price_change_reason_option
    if price_change_reason.present?
      Settings.order_detail_price_change_reason_options.include?(price_change_reason) ? price_change_reason : "Other"
    end
  end

  def notify_purchaser_of_order_status
    if product.email_purchasers_on_order_status_changes? && !reconciled?
      Notifier.order_detail_status_changed(id).deliver_later
    end
  end

  private

  # Is there enough information to move an associated order to complete/problem?
  def time_data_completeable?
    canceled_at.present? || time_data.order_completable?
  end

  def time_for_policy_lookup
    if fulfilled_at
      fulfilled_at
    elsif reservation.try(:canceled?)
      Time.current
    end
  end

  def calculated_costs
    price_policy&.calculate_cost_and_subsidy_from_order_detail(self) || {}
  end

  def make_complete
    # Don't update fulfilled_at if it was manually set.
    self.fulfilled_at = @manual_fulfilled_at.presence || Time.current
    assign_price_policy
    self.reviewed_at = Time.zone.now unless SettingsHelper.has_review_period?
  end

  def cancel_with_fee(order_status)
    assign_price_policy unless price_policy

    calculator = CancellationFeeCalculator.new(self)

    change_status!(calculator.total_cost > 0 ? OrderStatus.complete : order_status)

    if calculator.costs.present?
      assign_attributes(
        actual_cost: calculator.costs[:cost],
        actual_subsidy: calculator.costs[:subsidy],
      )
    end

    # If the status did not change in change_status! (e.g. it was complete, but
    # then changed to complete with cancellation fee), then it doesn't trigger a save,
    # so we need to do it ourselves.
    save!
  end

  def mark_dispute_resolved
    if resolve_dispute == true || resolve_dispute == "1"
      self.dispute_resolved_at = Time.zone.now
      self.reviewed_at         = Time.zone.now
    else
      resolve_dispute = "0"
    end
  end

  def clear_costs
    self.actual_cost     = nil
    self.actual_subsidy  = nil
    self.price_policy_id = nil
  end

  def reset_dispute
    if dispute_resolved_at_changed?
      if errors.any?
        self.dispute_resolved_at = dispute_resolved_at_was
        self.reviewed_at         = reviewed_at_was
      end
    end
  end

  def clear_statement
    if statement.present?
      statement.remove_order_detail(self)
      self.statement = nil
    end
  end

  def update_fulfilled_at_on_resolve
    if problem_changed? && !problem_order?
      self.fulfilled_at = time_data.actual_end_at if time_data.actual_end_at
    end
  end

  def set_reconciled_at
    # Do not override it if it has been set by something already (e.g. journaling)
    self.reconciled_at ||= Time.current
  end

  def pricing_note_required?
    return false unless @manually_priced && SettingsHelper.feature_on?(:price_change_reason_required)
    return false if cost_estimated? || canceled_at?

    !actual_costs_match_calculated?
  end

  def update_billable_minutes_on_reservation
    reservation.update_billable_minutes
  end
end
