# frozen_string_literal: true

class ResearchSafetyCertificate < ApplicationRecord

  include ActiveModel::ForbiddenAttributesProtection

  # This class was formerly in an NU-specific engine.
  # TODO: Rename the table
  self.table_name = "nu_safety_certificates"

  belongs_to :deleted_by, class_name: 'User'

  acts_as_paranoid # soft-delete functionality

  validates :name, presence: true
  validates :name, uniqueness: { scope: :deleted_at }

  has_many :product_certification_requirements, class_name: "ProductResearchSafetyCertificationRequirement",
                                                foreign_key: "nu_safety_certificate_id",
                                                dependent: :destroy
  has_many :products, through: :product_certification_requirements

  scope :ordered, -> { order(:name) }

end


