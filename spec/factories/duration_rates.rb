# frozen_string_literal: true

FactoryBot.define do
  factory :duration_rate do
    min_duration_hours { 1 }
    rate { 60 }
  end

end
