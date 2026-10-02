# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :feature_setting) do |example|
    example.metadata[:feature_setting].except(:reload_routes).each do |feature, value|
      keys = feature.to_s.split(".")
      target = keys[0..-2].reduce(Settings.feature) { |node, key| node[key] }
      target[keys.last] = value
    end

    Nucore::Application.reload_routes! if example.metadata[:feature_setting][:reload_routes]

    example.call

    Settings.reload!
    Nucore::Application.reload_routes! if example.metadata[:feature_setting][:reload_routes]
  end

  config.around(:each, :billing_review_period) do |example|
    original_review_period = Settings.billing.review_period
    Settings.billing.review_period = example.metadata[:billing_review_period]

    example.call

    Settings.billing.review_period = original_review_period
  end

  config.around(:each, :safety_adapter_class) do |example|
    original_class = ResearchSafetyCertificationLookup.adapter_class
    ResearchSafetyCertificationLookup.adapter_class = example.metadata[:safety_adapter_class]

    example.call

    ResearchSafetyCertificationLookup.adapter_class = original_class
  end
end
