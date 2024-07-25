# frozen_string_literal: true

FactoryBot.define do
  factory :project, class: Project do
    sequence(:name) { |n| "Project #{n}" }
    facility

    trait :inactive do
      active { false }
    end
  end
end
