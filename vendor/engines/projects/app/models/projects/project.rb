# frozen_string_literal: true

module Projects

  class Project < ApplicationRecord

    belongs_to :facility, foreign_key: :facility_id
    has_many :order_details, inverse_of: :project

    validates :facility_id, presence: true
    validates :name,
              presence: true,
              uniqueness: { case_sensitive: false, scope: :facility_id }

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }
    scope :display_order, -> { order(:name) }

    def to_s
      name
    end

    # This returns the total cost using actual cost if the order has it, otherwise
    # uses the estimated cost.
    def total_cost
      order_details.inject(0) { |sum, od| sum += od.total }
    end

  end

end
