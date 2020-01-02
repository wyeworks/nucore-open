# frozen_string_literal: true

module NuResearchSafety

  class Certificate < ApplicationRecord

    include ActiveModel::ForbiddenAttributesProtection

    self.table_name = "nu_safety_certificates"

    belongs_to :deleted_by, class_name: 'User'

    acts_as_paranoid # soft-delete functionality

    validates :name, presence: true
    validates :name, uniqueness: { scope: :deleted_at }

    has_many :product_certification_requirements, class_name: NuResearchSafety::ProductCertificationRequirement,
                                                  foreign_key: "nu_safety_certificate_id",
                                                  dependent: :destroy
    has_many :products, through: :product_certification_requirements

    scope :ordered, -> { order(:name) }

  end

end
