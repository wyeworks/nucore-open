# frozen_string_literal: true

class OrderStatus < ApplicationRecord

  has_many :order_details
  belongs_to :facility, optional: true
  belongs_to :parent, class_name: "OrderStatus", optional: true
  has_many :children, class_name: "OrderStatus", foreign_key: :parent_id

  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:parent_id, :facility_id], case_sensitive: false
  validates_each :parent_id do |model, attr, value|
    begin
      model.errors.add(attr, "must be a root") unless value.nil? || OrderStatus.unscoped.find(value).root?
    rescue => e
      model.errors.add(attr, "must be a valid root")
    end
  end

  NEW = "New".freeze
  IN_PROCESS = "In Process".freeze
  CANCELED = "Canceled".freeze
  COMPLETE = "Complete".freeze
  RECONCILED = "Reconciled".freeze
  UNRECOVERABLE = "Unrecoverable".freeze

  ROOT_STATUS_ORDER = [NEW, IN_PROCESS, CANCELED, COMPLETE, RECONCILED, UNRECOVERABLE].freeze

  # Needs to be overridable by engines
  cattr_accessor(:ordered_root_statuses) { ROOT_STATUS_ORDER.dup }

  scope :for_facility, ->(facility) { where(facility_id: [nil, facility&.id]) }
  scope :by_name, ->(name) { find_by(name: name) }
  scope :by_names, ->(names) { where(name: names) }

  # This one is different because `new` is a reserved keyword
  def self.new_status
    by_name(NEW)
  end

  def self.in_process
    by_name(IN_PROCESS)
  end

  def self.canceled
    by_name(CANCELED)
  end

  def self.complete
    by_name(COMPLETE)
  end

  def self.reconciled
    by_name(RECONCILED)
  end

  def self.unrecoverable
    by_name(UNRECOVERABLE)
  end

  def self.add_to_order_statuses(facility)
    non_protected_statuses(facility) - [canceled]
  end

  def self.roots
    where(parent_id: nil)
  end

  def self_and_descendants
    self.class.where(parent_id: id).or(self.class.where(id: id))
  end

  def self.canceled_statuses_for_facility(facility)
    canceled.self_and_descendants.for_facility(facility).sorted
  end

  def self.sorted
    all.sort_by(&:position)
  end

  def root?
    parent_id.nil?
  end

  def root
    parent || self
  end

  def editable?
    !!facility
  end

  def state_name
    root.name.downcase.delete(" ").to_sym
  end

  def position
    [ordered_root_statuses.index(root.name), id]
  end

  def name_with_level
    level_indicator = root? ? "" : "-"
    "#{level_indicator} #{name}".strip
  end

  def to_s
    name
  end

  def root_canceled?
    root == OrderStatus.canceled
  end

  class << self

    def root_statuses
      roots.sort_by(&:position)
    end

    def default_order_status
      root_statuses.first
    end

    def initial_statuses(facility, product: nil)
      statuses = new_status.self_and_descendants
        .or(in_process.self_and_descendants)

      if SettingsHelper.feature_on?(:item_initial_order_status_complete) && product.is_a?(Item)
        statuses = statuses.or(complete.self_and_descendants)
      end

      statuses.for_facility(facility).sorted
    end

    def non_protected_statuses(facility)
      new_status.self_and_descendants
        .or(in_process.self_and_descendants)
        .or(canceled.self_and_descendants)
        .or(unrecoverable.self_and_descendants)
        .or(complete.self_and_descendants)
        .for_facility(facility).sorted
    end

  end

end
