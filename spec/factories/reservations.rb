# frozen_string_literal: true

FactoryBot.define do
  factory :reservation do
    transient do
      duration { nil }
    end

    after(:build) do |reservation, evaluator|
      if evaluator.duration.present? && reservation.reserve_start_at.present?
        reservation.reserve_end_at = reservation.reserve_start_at + evaluator.duration
      end
    end

    reserve_start_at { Time.zone.parse("#{Date.today} 10:00:00") + 1.day }
    reserve_end_at { reserve_start_at + 1.hour }

    trait :canceled do
      after(:create) do |reservation|
        reservation.order_detail.update(canceled_at: 1.minute.ago)
      end
    end

    trait :inprocess do
      after(:create) do |reservation|
        reservation.order_detail.to_inprocess
      end
    end

    trait :yesterday do
      reserve_start_at { Time.zone.parse("#{Date.today} 10:00:00") - 1.day }
    end

    trait :later_yesterday do
      reserve_start_at { Time.zone.parse("#{Date.today} 10:00:00") - 1.day + 1.hour }
    end

    trait :later_today do
      reserve_start_at { 2.hours.from_now }
    end

    trait :running do
      reserve_start_at { 15.minutes.ago }
      reserve_end_at { 45.minutes.from_now }
      actual_start_at { 15.minutes.ago }
    end

    trait :long_running do
      yesterday
      actual_start_at { reserve_start_at }
      actual_end_at { nil }
    end

    trait :started_early do
      running
      actual_start_at { reserve_start_at - 5.minutes }
    end

    trait :tomorrow do
      reserve_start_at { 1.day.from_now }
    end

    # :daily sets each reservation to 10am, one day after the previous.
    # Use when creating lists so reservations don't overlap.
    trait :daily do
      sequence(:reserve_start_at) do |n|
        Date.today.beginning_of_day + 10.hours + n.days
      end
    end
  end

  factory :admin_reservation, class: AdminReservation, parent: :reservation do
    order_detail { nil }
    category { AdminReservation::CATEGORIES.sample }
  end

  factory :offline_reservation, class: OfflineReservation, parent: :reservation do
    admin_note { "Out of order" }
    category { "out_of_order" }
    order_detail { nil }

    OfflineReservation::CATEGORIES.each do |category_label|
      trait category_label.to_sym do
        category { category_label }
      end
    end
  end

  factory :setup_reservation, class: Reservation, parent: :reservation do
    product factory: :setup_instrument

    order_detail { FactoryBot.create(:setup_order, product:).order_details.first }
  end

  factory :validated_reservation, parent: :setup_reservation do
    after(:create) do |reservation|
      reservation.order.validate_order!
    end
  end

  factory :purchased_reservation, parent: :validated_reservation do
    transient { user { nil } }

    after(:create) do |reservation, evaluator|
      reservation.order.update_attribute(:user_id, evaluator.user.id) if evaluator.user
      reservation.order.purchase!
    end

    factory :completed_reservation do
      reserve_start_at { Time.zone.parse("#{Date.today} 10:00:00") - 1.day }
      reserve_end_at { Time.zone.parse("#{Date.today} 10:00:00") - 23.hours }
      reserved_by_admin { true }

      after(:create) do |reservation|
        reservation.order_detail.backdate_to_complete! reservation.reserve_end_at
      end
    end
  end
end
