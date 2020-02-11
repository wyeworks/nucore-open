# frozen_string_literal: true

class Account < ApplicationRecord

  module Overridable

    def price_groups
      (price_group_members.collect(&:price_group) + (owner_user ? owner_user.price_groups : [])).uniq
    end

  end

  include Overridable
  include Accounts::AccountNumberSectionable
  include DateHelper
  include NUCore::Database::WhereIdsIn

  # belongs_to :facility, required: false
  has_many :account_facility_joins
  has_many :facilities, -> { merge(Facility.active) }, through: :account_facility_joins

  # Temporary methods
  def facility
    facilities.first
  end

  def facility_id=(facility_id)
    self[:facility_id] = facility_id
    self.account_facility_joins = [AccountFacilityJoin.new(facility_id: facility_id, account: self)] if facility_id
  end

  def facility=(facility)
    self.facility_id = facility&.id
  end
  # Temporary methods

  has_many :account_users, -> { where(deleted_at: nil) }, inverse_of: :account
  has_many :deleted_account_users, -> { where.not(deleted_at: nil) }, class_name: "AccountUser"

  has_one :owner, -> { where(user_role: AccountUser::ACCOUNT_OWNER, deleted_at: nil) }, class_name: "AccountUser"
  has_one :owner_user, through: :owner, source: :user
  has_many :business_admins, -> { where(user_role: AccountUser::ACCOUNT_ADMINISTRATOR, deleted_at: nil) }, class_name: "AccountUser"

  has_many :notify_user_roles, -> { where(user_role: AccountUser.admin_user_roles, deleted_at: nil) }, class_name: "AccountUser"
  has_many :notify_users, through: :notify_user_roles, source: :user

  has_many   :price_group_members
  has_many   :order_details
  has_many   :orders
  has_many   :statements, through: :order_details
  has_many   :payments, inverse_of: :account
  belongs_to :affiliate
  accepts_nested_attributes_for :account_users
  has_many :log_events, as: :loggable

  scope :active, -> { where("expires_at > ?", Time.current).where(suspended_at: nil) }
  scope :administered_by, lambda { |user|
    for_user(user).where("account_users.user_role" => AccountUser.admin_user_roles)
  }
  scope :global, -> { where(type: config.global_account_types) }
  scope :per_facility, -> { where(type: config.facility_account_types) }

  validates_presence_of :account_number, :description, :expires_at, :created_by, :type
  validates_length_of :description, maximum: 50

  validate { errors.add(:base, :missing_owner) if missing_owner? }

  delegate :administrators, to: :account_users
  delegate :global?, :per_facility?, to: :class

  # The @@config class variable stores account configuration details via a
  # seperate `AccountConfig` class. This way downstream repositories can use
  # customized account configurations. Also the `Account` model stays as thin
  # as possible by striving to contain only methods related to database logic.
  def self.config
    @@config ||= AccountConfig.new
  end

  # Returns true if this account type is limited to a single facility.
  def self.per_facility?
    config.per_facility?(name)
  end

  # Returns true if this account type can cross multiple facilities.
  def self.global?
    config.global?(name)
  end

  # Returns true if this account type supports affiliate.
  def self.using_affiliate?
    config.using_affiliate?(name)
  end

  # Returns true if this account type supports statements.
  def self.using_statements?
    config.using_statements?(name)
  end

  # Returns true if this account type supports journal.
  def self.using_journal?
    config.using_journal?(name)
  end

  def self.for_facility(facility)
    if facility.single_facility?
      # In order to use `or`, the structures of both sides need to be identical
      structure = left_outer_joins(:facilities).references(:account_facility_joins)
      structure.global
               .or(structure.per_facility.where(account_facility_joins: { facility_id: facility.id }))
    else
      all
    end
  end

  def self.for_user(user)
    joins(:account_users).where(account_users: { user_id: user.id })
  end

  def self.for_order_detail(order_detail)
    for_user(order_detail.user).for_facility(order_detail.facility)
  end

  def self.with_orders_for_facility(facility)
    where(id: ids_with_orders(facility))
  end

  def type_string
    I18n.t("activerecord.models.#{self.class.to_s.underscore}.one", default: self.class.model_name.human)
  end

  def <=>(other)
    account_number <=> other.account_number
  end

  def owner_user_name
    owner_user.try(:name) || ""
  end

  def business_admin_users
    business_admins.collect(&:user)
  end

  def suspend
    update_attributes(suspended_at: Time.current)
  end

  def unsuspend
    update_attributes(suspended_at: nil)
  end

  def display_status
    if suspended?
      I18n.t("account.statuses.suspended")
    else
      I18n.t("account.statuses.active")
    end
  end

  def suspended?
    !suspended_at.blank?
  end

  def expired?
    expires_at && expires_at <= Time.zone.now
  end

  def formatted_expires_at
    expires_at.try(:strftime, "%m/%d/%Y")
  end

  def formatted_expires_at=(str)
    self.expires_at = parse_usa_date(str) if str
  end

  def account_list_item
    "#{account_number} #{description}"
  end

  def validate_against_product(product, user)
    # does the facility accept payment method?
    return "#{product.facility.name} does not accept #{type_string} payment" unless product.facility.can_pay_with_account?(self)

    # does the product have a price policy for the user or account groups?
    return "The #{type_string} has insufficient price groups" unless product.can_purchase?((price_groups + user.price_groups).flatten.uniq.collect(&:id))

    # check chart string account number
    if respond_to?(:account_open?)
      accts = product.is_a?(Bundle) ? product.products.collect(&:account) : [product.account]
      accts.uniq.each do |acct|
        return I18n.t("not_open", model: type_string, scope: "activerecord.errors.models.account") unless account_open?(acct)
      end
    end

    nil
  end

  def can_reconcile?(order_detail)
    if self.class.using_journal?
      order_detail.journal.try(:successful?) || order_detail.ready_for_journal?
    elsif self.class.using_statements?
      order_detail.statement_id.present?
    else
      false
    end
  end

  # TODO: Only used in demo:seeds
  def self.need_statements(facility)
    # find details that are complete, not yet statemented, priced, and not in dispute
    details = OrderDetail.need_statement(facility)
    find(details.collect(&:account_id).uniq || [])
  end

  def facility_balance(facility, date = Time.zone.now)
    details = OrderDetail.for_facility(facility).complete.where("order_details.fulfilled_at <= ? AND price_policy_id IS NOT NULL AND order_details.account_id = ?", date, id)
    details.collect(&:total).sum.to_f
  end

  def unreconciled_order_details(facility)
    OrderDetail.account_unreconciled(facility, self)
  end

  def unreconciled_total(facility, order_details = unreconciled_order_details(facility))
    order_details.inject(0) do |balance, order_detail|
      cost = order_detail.cost_estimated? ? order_detail.estimated_total : order_detail.actual_total
      balance += cost if cost
      balance
    end
  end

  def update_order_details_with_statement(statement)
    details = order_details.joins(:order)
                           .where("orders.facility_id = ? AND order_details.reviewed_at < ? AND order_details.statement_id IS NULL", statement.facility.id, Time.zone.now)
                           .readonly(false)
                           .to_a

    details.each { |od| od.update_attributes(reviewed_at: Time.zone.now + Settings.billing.review_period, statement: statement) }
  end

  def can_be_used_by?(user)
    !account_users.where("user_id = ? AND deleted_at IS NULL", user.id).first.nil?
  end

  def active?
    !expired? && !suspended?
  end

  delegate :to_s, to: :account_number, prefix: true

  def to_s(with_owner = false, flag_suspended = true, with_facility: false)
    desc = "#{description} / #{account_number_to_s}"
    desc += " / #{owner_user_name}" if with_owner && owner_user.present?
    desc += " (#{display_status.upcase})" if flag_suspended && suspended?
    desc
  end

  def affiliate_to_s
    return "" unless affiliate
    if affiliate.subaffiliates_enabled?
      "#{affiliate.name}: #{affiliate_other}"
    else
      affiliate.name
    end
  end

  def description_to_s
    if suspended?
      "#{description} (#{display_status.upcase})"
    else
      description
    end
  end

  # Optionally override this method for models that inherit from Account.
  # Forces journal rows to be destroyed and recreated when an order detail is
  # updated.
  def recreate_journal_rows_on_order_detail_update?
    false
  end

  def missing_owner?
    account_users.none? { |au| au.active? && au.owner? }
  end

  private

  def self.ids_with_orders(facility)
    relation = joins(order_details: :order)
    relation = relation.where("orders.facility_id = ?", facility) if facility.single_facility?
    relation.select("distinct order_details.account_id")
  end

end
