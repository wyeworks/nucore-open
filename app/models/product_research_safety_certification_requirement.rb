# frozen_string_literal: true

class ProductResearchSafetyCertificationRequirement < ApplicationRecord

  # This class was formerly in an NU-specific engine.
  # TODO: Rename the table
  self.table_name = "nu_product_cert_requirements"

  acts_as_paranoid # soft-delete functionality

  belongs_to :product
  # TODO: Rename the foreign key column
  belongs_to :research_safety_certificate, foreign_key: :nu_safety_certificate_id

  validates :product, presence: true
  validates :research_safety_certificate, presence: true
  validates :research_safety_certificate, uniqueness: { scope: [:deleted_at, :product_id] }

end
