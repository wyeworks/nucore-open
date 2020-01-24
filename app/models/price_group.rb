# frozen_string_literal: true

class PriceGroup < ApplicationRecord

  belongs_to :facility
  has_many   :price_policies
  has_many   :order_details, through: :price_policies, dependent: :restrict_with_exception
  has_many   :price_group_members, dependent: :destroy
  has_many   :user_price_group_members, class_name: "UserPriceGroupMember"
  has_many   :account_price_group_members, class_name: "AccountPriceGroupMember"

  validates_presence_of   :facility_id # enforce facility constraint here, though it's not always required
  validates_presence_of   :name
  validates_uniqueness_of :name, scope: :facility_id

  default_scope -> { order(is_internal: :desc, display_order: :asc, name: :asc) }

  before_destroy { throw :abort if global? }
  before_destroy { price_policies.destroy_all } # Cannot be a dependent: :destroy because of ordering of callbacks
  before_create  ->(o) { o.display_order = 999 unless o.facility_id.nil? }

  scope :for_facility, ->(facility) { where(facility_id: [nil, facility.id]) }
  scope :globals, -> { where(facility_id: nil) }

  def self.base
    globals.find_by(name: Settings.price_group.name.base)
  end

  def self.external
    globals.find_by(name: Settings.price_group.name.external)
  end

  def self.cancer_center
    globals.find_by(name: Settings.price_group.name.cancer_center)
  end

  def is_not_global?
    !global?
  end

  def global?
    facility.nil?
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

end
