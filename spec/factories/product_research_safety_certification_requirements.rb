# frozen_string_literal: true

FactoryBot.define do
  factory :product_certification_requirement, class: ProductResearchSafetyCertificationRequirement do
    association :product, factory: :setup_instrument
    association :research_safety_certificate
    deleted_at { nil }
    deleted_by_id { nil }
  end
end
