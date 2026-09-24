# frozen_string_literal: true

RSpec.configure do |config|
  config.include ActiveJob::TestHelper

  config.around(:each, :perform_enqueued_jobs) do |example|
    perform_enqueued_jobs do
      example.run
    end
  end
end
