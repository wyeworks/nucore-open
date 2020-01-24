# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    description { "Lorem ipsum..." }
    account { 71_234 }
    requires_approval { false }
    is_archived { false }
    is_hidden { false }
    initial_order_status_id { FactoryBot.create(:order_status, name: "New").id }

    after(:build) do |product|
      if product.facility_account.present?
        product.facility ||= product.facility_account.facility
      else
        product.facility_account = product.facility&.facility_accounts&.first
      end
    end

    factory :instrument, class: Instrument do
      transient do
        no_relay { false }
      end

      sequence(:name) { |n| "Instrument #{n}" }
      sequence(:url_name) { |n| "instrument#{n}" }
      min_reserve_mins { 60 }
      max_reserve_mins { 120 }
      reserve_interval { 1 }

      after(:create) do |inst, evaluator|
        inst.relay = FactoryBot.create(:relay_dummy, instrument: inst) unless evaluator.no_relay
      end
    end

    factory :item, class: Item do
      sequence(:name) { |n| "Item #{n}" }
      sequence(:url_name) { |n| "item_url_#{n}" }
    end

    factory :service, class: Service do
      sequence(:name) { |n| "Service #{n}" }
      sequence(:url_name) { |n| "service#{n}" }
    end

    factory :timed_service, class: TimedService do
      sequence(:name) { |n| "Timed Service #{n}" }
      sequence(:url_name) { |n| "timed_service#{n}" }
    end

    factory :bundle, class: Bundle do
      transient do
        bundle_products { [] }
      end

      account { nil } # bundles don't have accounts
      sequence(:name) { |n| "Bundle #{n}" }
      sequence(:url_name) { |n| "bundle-#{n}" }

      after(:create) do |bundle, evaluator|
        evaluator.bundle_products.each do |product|
          BundleProduct.create!(bundle: bundle, product: product, quantity: 1)
        end
      end
    end

    trait :archived do
      is_archived { true }
    end

    trait :hidden do
      is_hidden { true }
    end
  end

  factory :setup_product, class: Product do
    facility factory: :setup_facility

    sequence(:name) { |n| "Product #{n}" }
    sequence(:url_name) { |n| "product-#{n}" }
    description { "Product description" }
    account { 71_234 }
    requires_approval { false }
    is_archived { false }
    is_hidden { false }
    initial_order_status { FactoryBot.create(:order_status, name: "New") }
    min_reserve_mins { 60 }
    max_reserve_mins { 120 }

    after(:build) do |product|
      product.facility_account ||= product.facility.facility_accounts.first
    end

    after(:create) do |product|
      FactoryBot.create(:price_group_product,
                        product: product,
                        price_group: product.facility.price_groups.last)
    end

    factory :setup_service, class: Service do
    end

    factory :setup_timed_service, class: TimedService do
      after(:create) do |product|
        create(:timed_service_price_policy, product: product, price_group: product.facility.price_groups.last)
      end
    end

    factory :setup_item, class: Item do
      after(:create) do |product|
        create(:item_price_policy, product: product, price_group: product.facility.price_groups.last)
      end
    end

    trait :with_facility_account do
      after(:build) do |product|
        product.facility_account = create(:facility_account, facility: product.facility)
      end
    end

    trait :with_order_form do
      after(:create) do |product|
        create(:stored_file, :template, product: product)
      end
    end
  end

  factory :setup_instrument, class: Instrument, parent: :setup_product do
    transient do
      charge_for { "reservation" }
    end

    reserve_interval { 1 }

    schedule { create :schedule, facility: facility }

    after(:create) do |product, evaluator|
      create :schedule_rule, product: product
      create :instrument_price_policy, price_group: product.facility.price_groups.last, usage_rate: 1, product: product, charge_for: evaluator.charge_for
      product.reload
    end

    trait :timer do
      transient do
        no_relay { false }
      end

      min_reserve_mins { 60 }
      max_reserve_mins { 120 }
      reserve_interval { 1 }

      after(:create) do |inst, evaluator|
        inst.relay = FactoryBot.create(:relay_dummy, instrument: inst) unless evaluator.no_relay
      end
    end

    trait :always_available do
      after(:create) do |product|
        product.schedule_rules.destroy_all
        create(:all_day_schedule_rule, product: product)
        product.reload
      end
    end

    trait :offline do
      after(:create) do |product|
        product
          .offline_reservations
          .create!(
            admin_note: "Offline",
            category: "out_of_order",
            reserve_start_at: 1.month.ago,
          )
      end
    end
  end

  factory :instrument_requiring_approval, parent: :setup_instrument do
    requires_approval { true }

    trait :disallowing_training_request do
      allows_training_requests { false }
    end
  end

end
