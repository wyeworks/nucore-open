# frozen_string_literal: true

FactoryBot.define do
  factory :certificate, class: NuResearchSafety::Certificate do
    sequence(:name) { |n| "Certificate #{n}" }
  end
end
