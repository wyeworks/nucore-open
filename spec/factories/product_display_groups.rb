# frozen_string_literal: true

FactoryBot.define do
  factory :product_display_group do
    sequence(:name) { |n| "Product Group #{n}"}
  end
end
