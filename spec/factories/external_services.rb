# frozen_string_literal: true

FactoryBot.define do
  factory :external_service, class: UrlService do
    location { "http://survey.test.local" }
  end

  factory :external_service_passer do
    external_service
    active { false }
    association :passer, factory: :setup_service
  end

  factory :external_service_receiver do
    external_service
    response_data { { show_url: "http://survey.test.local/show", edit_url: "http://survey.test.local/edit" }.to_json }

    after :build do |esr|
      service = create :setup_service
      order = create :purchased_order, product: service
      esr.receiver = create :order_detail, order:, product: service
    end
  end
end
