# frozen_string_literal: true

FactoryBot.define do
  factory :order_detail do
    quantity { 1 }
    created_by { 0 }
    state { "new" }
    order_status { nil }

    trait :purchased do
      order_status { OrderStatus.new_status }
      ordered_at { Time.current }
    end

    trait :completed do
      state { "complete" }
      order_status { OrderStatus.complete }
    end

    trait :canceled do
      state { "canceled" }
      order_status { OrderStatus.canceled }
    end

    trait :canceled_with_cost do
      state { "complete" }
      order_status { OrderStatus.complete }
      canceled_at { 30.minutes.ago }
      actual_cost { 5 }
    end

    trait :disputed do
      completed
      reviewed_at { 5.days.ago }
      dispute_at { 3.days.ago }
      association :dispute_by, factory: :user
      dispute_reason { "No, sir. I don't like it." }
    end
  end

end
