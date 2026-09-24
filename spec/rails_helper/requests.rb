# frozen_string_literal: true

require "paperclip/matchers"
require "active_storage_validations/matchers"

RSpec.configure do |config|
  config.include CapybaraRequests, type: :request

  # for testing attachment validations
  config.include Paperclip::Shoulda::Matchers
  config.include ActiveStorageValidations::Matchers

  config.around(:each, :disable_requests_local) do |example|
    Rails.application.env_config.tap do |app_config|
      prev_show_exceptions = app_config['action_dispatch.show_exceptions']
      prev_requests_local = app_config['consider_all_requests_local']
      prev_detailed_exceptions = app_config['action_dispatch.show_detailed_exceptions']
      app_config['action_dispatch.show_exceptions'] = :rescuable
      app_config['consider_all_requests_local'] = false
      app_config['action_dispatch.show_detailed_exceptions'] = false

      example.run
      app_config['action_dispatch.show_exceptions'] = prev_show_exceptions
      app_config['consider_all_requests_local'] = prev_requests_local
      app_config['action_dispatch.show_detailed_exceptions'] = prev_detailed_exceptions
    end
  end
end
