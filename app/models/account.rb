class Account < ActiveRecord::Base

  module Overridable

    def price_groups
      (price_group_members.collect(&:price_group) + (owner_user ? owner_user.price_groups : [])).uniq
    end

  end

  include Overridable
  include Accounts::AccountNumberSectionable
  include DateHelper
  include NUCore::Database::WhereIdsIn
  include Loggable

  has_many :account_users, -> { where(deleted_at: nil) }, inverse_of: :account
  has_many :deleted_account_users, -> { where.not("account_users.deleted_at" => nil) }, class_name: "AccountUser"
  # Using a basic hash doesn't work with the `owner_user` :through association. It would
  # only include the last item in the hash as part of the scoping.
  # TODO Consider changing when we get to Rails 4.
  has_one :owner, -> { where("account_users.user_role = '#{AccountUser::ACCOUNT_OWNER}' AND account_users.deleted_at IS NULL") }, class_name: "AccountUser"
  has_one :owner_user, through: :owner, source: :user
  has_many :business_admins, -> { where(user_role: AccountUser::ACCOUNT_ADMINISTRATOR, deleted_at: nil) }, class_name: "AccountUser"
  has_many   :price_group_members
  has_many   :order_details
  has_many   :orders
  has_many   :statements, through: :order_details
  has_many   :payments, inverse_of: :account
  belongs_to :affiliate
  accepts_nested_attributes_for :account_users

  scope :active, -> { where("expires_at > ?", Time.current).where(suspended_at: nil) }
  scope :administered_by, lambda { |user|
    for_user(user).where("account_users.user_role" => AccountUser.admin_user_roles)
  }
  scope :global_account_types, -> { where(accounts: { type: config.global_account_types }) }

  validates_presence_of :account_number, :description, :expires_at, :created_by, :type
  validates_length_of :description, maximum: 50

  validate do |acct|
    # a current account owner if required
    # don't use a scope so we can validate on nested attributes
    unless acct.account_users.any? { |au| au.deleted_at.nil? && au.user_role == AccountUser::ACCOUNT_OWNER }
      acct.errors.add(:base, "Must have an account owner")
    end
  end

  delegate :administrators, to: :account_users

  # The @@config class variable stores account configuration details via a
  # seperate `AccountConfig` class. This way downstream repositories can use
  # customized account configurations. Also the `Account` model stays as thin
  # as possible by striving to contain only methods related to database logic.
  def self.config
    @@config ||= AccountConfig.new
  end

  # Returns true if this account type is limited to a single facility.
  def self.single_facility?
    config.single_facility?(name)
  end

  # Returns true if this account type can cross multiple facilities.
  def self.cross_facility?
    config.cross_facility?(name)
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
      where(
        "accounts.type in (:allow_all) or (accounts.type in (:limit_one) and accounts.facility_id = :facility)",
        allow_all: config.global_account_types,
        limit_one: config.facility_account_types,
        facility: facility,
      )
    else
      all
    end
  end

  def self.for_user(user)
    joins(:account_users).where(account_users: { user_id: user.id })
  end

  def self.for_order_detail(order_detail)
    for_user(order_detail.user)
      .where(facility_id: [nil, order_detail.facility.id])
  end

  def self.with_orders_for_facility(facility)
    where(id: ids_with_orders(facility))
  end

  # The subclassed Account objects will be cross facility by default; override
  # this method with `belongs_to :facility` if the subclassed Account object is
  # always scoped to a single facility.
  def facility
    nil
  end

  def facilities
    if facility_id
      # return a relation
      Facility.active.where(id: facility_id)
    else
      Facility.active
    end
  end

  def type_string
    I18n.t("activerecord.models.#{self.class.to_s.underscore}.one", default: self.class.model_name.human)
  end

  def <=>(obj)
    account_number <=> obj.account_number
  end

  def owner_user_name
    owner_user.try(:name) || ""
  end

  def business_admin_users
    business_admins.collect(&:user)
  end

  def notify_users
    [owner_user] + business_admin_users
  end

  def suspend
    update_attributes(suspended_at: Time.current)
  end

  def unsuspend
    update_attributes(suspended_at: nil)
  end

  def display_status
    if suspended?
      I18n.t("activerecord.models.account.statuses.suspended")
    else
      I18n.t("activerecord.models.account.statuses.active")
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

  def account_pretty
    to_s true
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
    if is_a?(NufsAccount)
      accts = product.is_a?(Bundle) ? product.products.collect(&:account) : [product.account]
      accts.uniq.each { |acct| return "The #{type_string} is not open for the required account" unless account_open?(acct) }
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

  def latest_facility_statement(facility)
    statements.latest(facility).first
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

  def is_active?
    !expired? && !suspended?
  end

  delegate :to_s, to: :account_number, prefix: true

  def to_s(with_owner = false, flag_suspended = true)
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

  def add_or_update_member(user, new_role, session_user)
    Account.transaction do
      # expire old owner if new
      if new_role == AccountUser::ACCOUNT_OWNER
        # expire old owner record
        @old_owner = owner
        if @old_owner
          @old_owner.deleted_at = Time.zone.now
          @old_owner.deleted_by = session_user.id
          @old_owner.save!
        end
      end

      # find non-deleted record for this user and account or init new one
      # deleted_at MUST be nil to preserve existing audit trail
      @account_user = AccountUser.find_or_initialize_by(account_id: id, user_id: user.id, deleted_at: nil)
      # set (new?) role
      @account_user.user_role = new_role
      # set creation information
      @account_user.created_by = session_user.id

      account_users << @account_user

      raise ActiveRecord::Rollback unless save
    end

    @account_user
  end

  # Optionally override this method for models that inherit from Account.
  # Forces journal rows to be destroyed and recreated when an order detail is
  # updated.
  def recreate_journal_rows_on_order_detail_update?
    false
  end

  private

  def self.ids_with_orders(facility)
    relation = joins(order_details: :order)
    relation = relation.where("orders.facility_id = ?", facility) if facility.single_facility?
    relation.select("distinct order_details.account_id")
  end

end
