# frozen_string_literal: true

FactoryBot.define do
  factory :scishield_training do
    user_id { User.first.id }
    sequence(:course_name) { |n| "Scishield Course Name #{n}" }
  end
end
