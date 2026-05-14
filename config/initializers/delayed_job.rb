# frozen_string_literal: true

# Handle retries with ActiveJob
Delayed::Worker.max_attempts = 0
