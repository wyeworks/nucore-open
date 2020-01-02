# frozen_string_literal: true

module NuResearchSafety

  module ProductExtension

    extend ActiveSupport::Concern

    included do
      has_many :product_certification_requirements, class_name: NuResearchSafety::ProductCertificationRequirement
      has_many :nu_safety_certificates, through: :product_certification_requirements

      alias_attribute :certificates, :nu_safety_certificates
    end

  end

end
