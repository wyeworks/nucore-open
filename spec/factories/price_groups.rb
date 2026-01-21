# frozen_string_literal: true

FactoryBot.define do
  factory :price_group do
    facility
    sequence(:name, "AAAAAAAA") { |n| "Price Group #{n}" }
    display_order { 999 }
    is_internal { true }
    admin_editable { true }

    trait :global do
      facility { nil }
      global { true }
      admin_editable { false }
    end

    trait :global_external do
      global
      is_internal { false }
    end

    trait :cancer_center do
      global
      admin_editable { true }
      sequence(:name, "AAAAAA") { |n| "Cancer Center #{n}" }
    end

    trait :hidden do
      is_hidden { true }
      sequence(:name, "AAAAAA") { |n| "Hidden Group #{n}" }
    end
  end

  factory :price_group_product do
    reservation_window { 1 }
  end

end
