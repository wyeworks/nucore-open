# frozen_string_literal: true

class Product < ApplicationRecord

  include TextHelpers::Translation
  include EmailListAttribute
  include FullTextSearch::Model

  belongs_to :facility
  belongs_to :initial_order_status, class_name: "OrderStatus"
  belongs_to :facility_account
  has_many :product_users
  has_many :order_details
  has_many :stored_files
  has_many :price_group_products
  has_many :price_groups, through: :price_group_products
  has_many :product_accessories, -> { where(deleted_at: nil) }, dependent: :destroy
  has_many :accessories, through: :product_accessories, class_name: "Product"
  has_many :price_policies
  has_many :training_requests, dependent: :destroy
  has_many :product_research_safety_certification_requirements
  has_many :research_safety_certificates, through: :product_research_safety_certification_requirements
  has_one :product_display_group_product
  has_one :product_display_group, through: :product_display_group_product

  # Instrument specifc
  has_one(
    :alert,
    dependent: :destroy,
    class_name: "InstrumentAlert",
    foreign_key: :instrument_id,
    inverse_of: :instrument
  )
  has_many :current_offline_reservations, -> { current }, class_name: "OfflineReservation"

  has_many :external_service_passers, as: :passer
  has_many :external_services, through: :external_service_passers

  before_save :start_time_disabled_daily_booking_only
  after_create :create_default_price_group_products
  after_create :create_skip_review_price_policies, if: :skip_review_mode?
  after_create :create_nonbillable_price_policy, if: :nonbillable_mode?

  email_list_attribute :training_request_contacts
  email_list_attribute :order_notification_recipients

  # Allow us to use `product.hidden?`
  alias_attribute :hidden, :is_hidden

  validates :type, presence: true
  validates :name, presence: true, length: { maximum: 200 }
  validate_url_name :url_name, :facility_id
  validates :user_notes_field_mode, presence: true, inclusion: Products::UserNoteMode.all
  validates :user_notes_label, length: { maximum: 255 }

  validates(
    :account,
    presence: true,
    numericality: { only_integer: true },
    length: { minimum: 1, maximum: Settings.accounts.product_default.to_s.length },
    if: -> { SettingsHelper.feature_on?(:expense_accounts) && requires_account? },
  )

  validates :facility_account_id, presence: true, if: :requires_account?

  # Use lambda so we can dynamically enable/disable in specs
  validate if: -> { SettingsHelper.feature_on?(:product_specific_contacts) } do
    errors.add(:contact_email, text("errors.models.product.attributes.contact_email.required")) unless email.present?
  end

  def self.billing_modes
    ["Default", "Skip Review", "Nonbillable"]
  end
  validates :billing_mode, inclusion: Product.billing_modes

  scope :active, -> { where(is_archived: false, is_hidden: false) }
  scope :alphabetized, -> { order(Arel.sql("LOWER(products.name)")) }
  scope :archived, -> { where(is_archived: true) }
  scope :available_for_estimates, -> { where({ type: %w[Item Service Instrument TimedService Bundle] }).not_archived }
  scope :not_archived, -> { where(is_archived: false) }
  scope :mergeable_into_order, -> { not_archived.where(type: mergeable_types) }
  scope :cross_core_available, -> { where(cross_core_ordering_available: true) }
  scope :in_active_facility, -> { joins(:facility).where(facilities: { is_active: true }) }
  scope :of_type, ->(type) { where(type:) }
  scope :with_schedule, -> { where.not(schedule_id: nil) }
  scope :without_display_group, -> { where.missing(:product_display_group_product) }

  # All product types. This cannot be a cattr_accessor because the block is evaluated
  # at definition time (not lazily as I expected) and this causes a circular dependency
  # in some schools.
  def self.types
    @types ||= [Instrument, Item, Service, TimedService, Bundle]
  end

  # Those that can be added to an order by an administrator
  def self.mergeable_types
    @mergeable_types ||= %w[Instrument Item Service TimedService Bundle]
  end

  # Those that can be ordered via the NUcore homepage
  def self.orderable_types
    @orderable_types ||= %w[Instrument Item Service TimedService Bundle]
  end

  # Products that can be used as accessories
  scope :accessorizable, -> { where(type: ["Item", "Service", "TimedService"]) }

  def self.exclude(products)
    where.not(id: products)
  end

  scope :for_facility, lambda { |facility|
    if facility.blank?
      none
    elsif facility.single_facility?
      where(facility_id: facility.id)
    else # cross-facility
      all
    end
  }

  def self.requiring_approval
    where(requires_approval: true)
  end

  def self.requiring_approval_by_type
    requiring_approval.group_by_type
  end

  def self.group_by_type
    order(:type, :name).group_by { |product| product.class.model_name.human }
  end

  def skip_order_review?
    nonbillable_mode? || skip_review_mode?
  end

  def nonbillable_mode?
    billing_mode == "Nonbillable"
  end

  def skip_review_mode?
    billing_mode == "Skip Review"
  end

  def default_mode?
    billing_mode == "Default"
  end

  def initial_order_status
    self[:initial_order_status_id] ? OrderStatus.find(self[:initial_order_status_id]) : OrderStatus.default_order_status
  end

  def current_price_policies(date = Time.zone.now)
    price_policies.current_for_date(date).purchaseable
  end

  def past_price_policies
    price_policies.past
  end

  def past_price_policies_grouped_by_start_date
    past_price_policies.order(start_date: :desc).group_by(&:start_date)
  end

  def upcoming_price_policies
    price_policies.upcoming
  end

  def upcoming_price_policies_grouped_by_start_date
    upcoming_price_policies.order(:start_date).group_by(&:start_date)
  end

  # TODO: favor the alphabetized scope over relying on Array#sort
  def <=>(other)
    name.casecmp other.name
  end

  # If there isn't an email specific to the product, fall back to the facility's email
  def email
    # If product_specific_contacts is off, always return the facility's email
    return facility.email unless SettingsHelper.feature_on? :product_specific_contacts
    contact_email.presence || facility.try(:email)
  end

  def description
    self[:description].html_safe if self[:description]
  end

  def parameterize
    self.class.to_s.parameterize.to_s.pluralize
  end

  def can_be_used_by?(user)
    if requires_approval?
      product_user_exists?(user)
    else
      true
    end
  end

  def to_param
    if errors[:url_name].nil?
      url_name
    else
      url_name_was
    end
  end

  def to_s
    name.presence || ""
  end

  def to_s_with_status
    to_s + (is_archived? ? " (inactive)" : "")
  end

  def create_default_price_group_products
    PriceGroup.globals.find_each do |price_group|
      price_group_products.create!(price_group:)
    end
  end

  def create_skip_review_price_policies
    PricePolicyBuilder.create_skip_review_for(self)
  end

  def create_nonbillable_price_policy
    PricePolicyBuilder.create_nonbillable_for(self)
  end

  def available_for_purchase?
    !is_archived? && facility.is_active?
  end

  def can_purchase?(group_ids)
    return false unless available_for_purchase?

    # return false if there are no existing policies at all
    return false if price_policies.empty?

    # return false if there are no existing policies for the user's groups, e.g. they're a new group
    return false if price_policies.for_price_groups(group_ids).empty?

    # if there are current rules, but the user is not part of them
    if price_policies.current.any?
      return price_policies.current.for_price_groups(group_ids).where(can_purchase: true).any?
    end

    # if there are no current price policies, find the most recent price policy for each group.
    # if one of those can purchase, then allow the purchase
    group_ids.each do |group_id|
      # .try is in case the query doesn't return any values
      return true if price_policies.for_price_groups(group_id).order(:expire_date).last.try(:can_purchase?)
    end

    false
  end

  def can_purchase_order_detail?(order_detail)
    can_purchase? order_detail.price_groups.map(&:id)
  end

  def cheapest_price_policy(detail, date = Time.zone.now)
    groups = detail.price_groups
    return nil if groups.empty?

    # When feature flag is enabled, try account price groups first, then fallback to all groups
    if detail.is_a?(OrderDetail) && detail.account && SettingsHelper.feature_on?(:user_based_price_groups_exclude_purchaser)
      account_price_groups = detail.account.price_group_members.collect(&:price_group)

      if account_price_groups.present?
        policy = find_cheapest_price_policy_for_groups(detail, date, account_price_groups)
        return policy if policy
      end
    end

    find_cheapest_price_policy_for_groups(detail, date, groups)
  end

  def product_type
    self.class.name.underscore.pluralize
  end

  # Used when displaying quantities throughout the site and when editing an order.
  def quantity_as_time?
    false
  end

  # Primarily used when adding to an existing order (merge orders)
  def order_quantity_as_time?
    false
  end

  def product_accessory_by_id(id)
    product_accessories.where(accessory_id: id).first
  end

  def has_product_access_groups?
    respond_to?(:product_access_groups) && product_access_groups.any?
  end

  def access_group_for_user(user)
    find_product_user(user).try(:product_access_group)
  end

  def find_product_user(user)
    product_users.find_by(user_id: user.id)
  end

  def visible?
    !hidden?
  end

  def requires_merge?
    false
  end

  def offline?
    false
  end

  def online?
    !offline?
  end

  def user_notes_field_mode
    Products::UserNoteMode[self[:user_notes_field_mode]]
  end

  def user_notes_field_mode=(str_value)
    self[:user_notes_field_mode] = Products::UserNoteMode[str_value]
  end

  def is_accessible_to_user?(user)
    is_operator = user&.operator_of?(facility)
    !(is_archived? || (is_hidden? && !is_operator))
  end

  def duration_pricing_mode?
    false
  end

  def daily_booking?
    false
  end

  def can_apply_discounts?
    true
  end

  def time_unit
    nil
  end

  def activation_change_action
    archived_changed = saved_change_to_is_archived?

    return unless archived_changed
    old_archived, new_archived = archived_changed ? saved_change_to_is_archived : [is_archived, is_archived]

    return if old_archived == new_archived

    if old_archived && !new_archived
      :activate
    elsif !old_archived && new_archived
      :deactivate
    end
  end

  def to_log_s
    "#{name} (#{type})"
  end

  protected

  def translation_scope
    self.class.i18n_scope
  end

  private

  def requires_account?
    true
  end

  def product_user_exists?(user)
    find_product_user(user).present?
  end

  def start_time_disabled_daily_booking_only
    self.start_time_disabled = start_time_disabled && daily_booking?
  end

  def find_cheapest_price_policy_for_groups(detail, date, groups)
    price_policies = current_price_policies(date).newest.to_a.delete_if { |pp| pp.restrict_purchase? || groups.exclude?(pp.price_group) }
    return nil if price_policies.empty?

    # provide a predictable ordering of price groups so that equal unit costs
    # are always handled the same way. Put the base group at the front of the
    # price policy array so that it takes precedence over all others that have
    # equal unit cost. See task #49823.
    base_ndx = price_policies.index { |pp| pp.price_group == PriceGroup.base }
    base = price_policies.delete_at base_ndx if base_ndx
    price_policies.sort! { |pp1, pp2| pp1.price_group.name <=> pp2.price_group.name }
    price_policies.unshift base if base

    if detail.is_a?(OrderDetail)
      price_policies.min_by do |pp|
        # default to very large number if the estimate returns a nil
        costs = pp.estimate_cost_and_subsidy_from_order_detail(detail) || { cost: 999_999_999, subsidy: 0 }
        costs[:cost] - costs[:subsidy]
      end
    elsif detail.is_a?(EstimateDetail) && SettingsHelper.feature_on?(:show_estimates_option)
      price_policies.min_by do |pp|
        # default to very large number if the estimate returns a nil
        pp.estimate_cost_from_estimate_detail(detail) || 999_999_999
      end
    end
  end

end
