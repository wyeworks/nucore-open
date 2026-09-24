# frozen_string_literal: true

require "spec_helper"

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "shoulda/matchers"
require "axe-rspec"

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Keep factory_bot v4 build strategy behaviour
# https://github.com/thoughtbot/factory_bot/blob/v6.5.0/GETTING_STARTED.md#build-strategies-1
FactoryBot.use_parent_strategy = false
# Increase stub instances ids so they
# don't overlap with db instances
FactoryBot::Strategy::Stub.next_id = 100_000

Capybara::Node::Base.prepend(CapybaraStaleNodeRetry)

require_relative "rails_helper/time_helpers"
require_relative "rails_helper/test_accounts"
require_relative "rails_helper/system_specs"
require_relative "rails_helper/feature_settings"
require_relative "rails_helper/database"
require_relative "rails_helper/active_job"
require_relative "rails_helper/auth"
require_relative "rails_helper/requests"
require_relative "rails_helper/locales"

RSpec.configure do |config|
  config.filter_rails_from_backtrace!
  config.filter_gems_from_backtrace("spring")
  # rspec-rails by default excludes stack traces from within vendor Lots of our
  # engines are under vendor, so we don't want to exclude them
  config.backtrace_exclusion_patterns.delete(%r{vendor/})

  config.use_transactional_fixtures = true

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, type: :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!

  config.include FactoryBot::Syntax::Methods
end

FactoryBot::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
