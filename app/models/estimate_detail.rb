# frozen_string_literal: true

class EstimateDetail < ApplicationRecord
  belongs_to :estimate, inverse_of: :estimate_details
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }

end
