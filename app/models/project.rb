# frozen_string_literal: true

class Project < ApplicationRecord

  belongs_to :facility, foreign_key: :facility_id
  has_many :order_details, inverse_of: :project
  has_many :orders, inverse_of: :cross_core_project, foreign_key: :cross_core_project_id

  validates :facility_id, presence: true
  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false, scope: :facility_id }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :display_order, -> { order(:name) }

  # This includes all projects which include any order from the given facility,
  # including projects that have orders from multiple facilities.
  scope :for_facility, lambda { |facility|
    joins(:orders).where(orders: { facility: })
  }

  scope :cross_core, lambda {
    joins(:orders)
      .where.not(orders: { cross_core_project_id: nil })
  }

  scope :for_single_facility, lambda { |facility|
    left_outer_joins(:orders)
      .where(orders: { cross_core_project_id: nil })
      .where(facility: facility)
  }

  def to_s
    name
  end

  # This returns the total cost using actual cost if the order has it, otherwise
  # uses the estimated cost.
  def total_cost
    order_details.inject(0) { |sum, od| sum += od.total }
  end

  def cross_core?
    orders.any?
  end

  def name
    return "#{facility.abbreviation} Project - #{id}" if cross_core?

    super
  end

end
