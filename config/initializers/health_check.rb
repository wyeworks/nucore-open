# frozen_string_literal: true

# See https://github.com/ianheggie/health_check for more options
HealthCheck.setup do |config|
  config.uri = "healthz"
end
