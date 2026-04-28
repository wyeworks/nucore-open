# frozen_string_literal: true

FactoryBot.define do
  factory :facility_user_permission do
    user
    facility
    read_access { true }
  end
end
