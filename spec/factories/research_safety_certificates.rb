# frozen_string_literal: true

FactoryBot.define do
  factory :research_safety_certificate do
    sequence(:name) { |n| "Certificate #{n}" }
  end
end
