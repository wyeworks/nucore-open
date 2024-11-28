# frozen_string_literal: true

class PriceGroup < ApplicationRecord

  acts_as_paranoid

  belongs_to :facility
  has_many   :price_policies
  has_many   :order_details, through: :price_policies, dependent: :restrict_with_exception
  has_many   :price_group_members, dependent: :destroy
  has_many   :user_price_group_members, class_name: "UserPriceGroupMember"
  has_many   :account_price_group_members, class_name: "AccountPriceGroupMember"
  has_many   :price_group_discounts, dependent: :destroy

  validates_presence_of   :facility_id, unless: :global?
  validates_presence_of   :name
  validates_uniqueness_of :name, scope: :facility_id, case_sensitive: false, unless: :deleted_at?

  default_scope -> { order(is_internal: :desc, display_order: :asc, name: :asc) }

  before_destroy { throw :abort if global? }
  before_destroy { price_policies.destroy_all } # Cannot be a dependent: :destroy because of ordering of callbacks
  before_create  ->(o) { o.display_order = 999 unless o.facility_id.nil? }
  before_update  :update_hidden_price_group_policies, if: :will_save_change_to_is_hidden? && :is_hidden

  scope :for_facility, ->(facility) { where(facility_id: [nil, facility.id]) }
  scope :globals, -> { where(facility_id: nil) }
  scope :by_display_order, -> { reorder(display_order: :asc, name: :asc) }
  scope :visible, -> { where(is_hidden: false) }

  def self.base
    @base ||= globals.find_by(name: Settings.price_group.name.base)
  end

  def self.external
    @external ||= globals.find_by(name: Settings.price_group.name.external)
  end

  def self.nonbillable
    base
  end

  # Create a global price group, if it does not exist, and setup all the
  # schedule rules with price group discounts for the price group.
  def self.setup_global(name:, is_internal: false, admin_editable: true, discount_percent: 0, display_order: nil)
    price_group = find_or_create_global(name:, is_internal:, admin_editable:, display_order:)
    price_group.setup_schedule_rules(discount_percent:)
    price_group.setup_skip_review_price_policies
    price_group
  end

  def is_not_global?
    !global?
  end

  def can_manage_price_group_members?
    is_not_global? || SettingsHelper.feature_on?(:can_manage_global_price_groups)
  end

  def can_purchase?(product)
    !PriceGroupProduct.find_by(price_group_id: id, product_id: product.id).nil?
  end

  def name
    master_internal? ? "#{I18n.t('institution_name')} #{self[:name]}" : self[:name]
  end

  def to_s
    name
  end

  def type_string
    is_internal? ? "Internal" : "External"
  end

  def master_internal?
    is_internal? && display_order == 1
  end

  def <=>(other)
    "#{display_order}-#{name}".casecmp("#{other.display_order}-#{other.name}")
  end

  def can_delete?
    # use !.any? because it uses SQL count(), unlike none?
    !global? && !order_details.any?
  end

  def external?
    !is_internal?
  end

  # Creates price group discounts for this price group, if they do not exist
  def setup_schedule_rules(discount_percent: nil)
    ScheduleRule.all.each do |schedule_rule|
      schedule_price_groups = schedule_rule.price_group_discounts.map(&:price_group)

      if schedule_price_groups.include? self
        puts("price_group_discount for #{self} already exists for schedule rule #{schedule_rule.id}") unless Rails.env.test?
        next
      end

      schedule_rule.price_group_discounts.create(
        price_group: self,
        discount_percent: discount_percent || schedule_rule.discount_percent # this column defaults to 0
      )

      puts("Created price_group_discount for #{self} and schedule rule #{schedule_rule.id}") unless Rails.env.test?
    end
  end

  # Creates a new price rule for all Skip Review products.
  # Price rules should not prevent any user from purchasing
  def setup_skip_review_price_policies
    Product.where(billing_mode: "Skip Review").each do |product|
      PricePolicyBuilder.create_skip_review_for(product, [self])
    end
  end

  private

  def update_hidden_price_group_policies
    policies = price_policies.current
    PricePolicyUpdater.restrict_purchase(policies)
  end

  # Find a global price group by name, or create it if it does not exist
  def self.find_or_create_global(name:, display_order:, is_internal: false, admin_editable: true)
    global_price_groups = PriceGroup.globals
    found_price_group = global_price_groups.find_by(name:)

    if found_price_group
      puts("Global price group '#{name}' already exists.") unless Rails.env.test?

      found_price_group
    else
      pg = PriceGroup.new(
        name:,
        is_internal:,
        admin_editable:,
        facility_id: nil,
        global: true,
        display_order: display_order || (global_price_groups.count + 1)
      )

      pg.save

      puts("Created global price group '#{name}'") unless Rails.env.test?

      pg
    end
  end
end
