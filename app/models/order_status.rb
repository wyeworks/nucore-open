# frozen_string_literal: true

class OrderStatus < ApplicationRecord

  acts_as_nested_set

  has_many :order_details
  belongs_to :facility

  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:parent_id, :facility_id]
  validates_each :parent_id do |model, attr, value|
    begin
      model.errors.add(attr, "must be a root") unless value.nil? || OrderStatus.find(value).root?
    rescue => e
      model.errors.add(attr, "must be a valid root")
    end
  end

  scope :for_facility, ->(facility) { where(facility_id: [nil, facility.id]).order(:lft) }

  # This one is different because `new` is a reserved keyword
  def self.new_status
    find_by(name: "New")
  end

  def self.complete
    find_by(name: "Complete")
  end

  def self.canceled
    find_by(name: "Canceled")
  end

  def self.in_process
    find_by(name: "In Process")
  end

  def self.reconciled
    find_by(name: "Reconciled")
  end

  def self.add_to_order_statuses(facility)
    non_protected_statuses(facility) - [canceled]
  end

  def editable?
    !!facility
  end

  def state_name
    root.name.downcase.delete(" ").to_sym
  end

  def is_left_of?(o)
    rgt < o.lft
  end

  def name_with_level
    "#{'-' * level} #{name}".strip
  end

  def to_s
    name
  end

  def root_canceled?
    root == OrderStatus.canceled
  end

  class << self

    def root_statuses
      roots.sort_by(&:lft)
    end

    def default_order_status
      root_statuses.first
    end

    def initial_statuses(facility)
      first_invalid_status = canceled
      statuses = all.sort_by(&:lft).reject do |os|
        !os.is_left_of?(first_invalid_status)
      end
      statuses.reject! { |os| os.facility_id != facility.id && !os.facility_id.nil? } unless facility.nil?
      statuses
    end

    def non_protected_statuses(facility)
      first_protected_status = reconciled
      statuses = all.sort_by(&:lft).reject do |os|
        !os.is_left_of?(first_protected_status)
      end
      statuses.reject! { |os| os.facility_id != facility.id && !os.facility_id.nil? } unless facility.nil?
      statuses
    end

  end

end
