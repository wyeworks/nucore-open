# frozen_string_literal: true

FactoryBot.define do
  factory :product_certification_requirement, class: NuResearchSafety::ProductCertificationRequirement do
    association :product, factory: :setup_instrument
    association :nu_safety_certificate, factory: :certificate
    deleted_at { nil }
    deleted_by_id { nil }
  end
end
