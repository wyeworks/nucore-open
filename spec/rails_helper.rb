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

RSpec.configure do |config|
  include ActiveJob::TestHelper

  config.filter_rails_from_backtrace!
  config.filter_gems_from_backtrace("spring")
  # rspec-rails by default excludes stack traces from within vendor Lots of our
  # engines are under vendor, so we don't want to exclude them
  config.backtrace_exclusion_patterns.delete(%r{vendor/})

  config.use_transactional_fixtures = true

  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless=new")
    options.add_argument("--window-size=1366,768")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-gpu")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--remote-debugging-pipe")

    Capybara.default_max_wait_time = 15

    if ENV["DOCKER_LOCAL_DEV"]
      Capybara.register_driver :selenium_remote do |app|
        Capybara::Selenium::Driver.new(app,
                                       browser: :remote,
                                       url: "http://selenium:4444/wd/hub",
                                       options:)
      end

      driven_by(:selenium_remote)
      Capybara.server_host = "0.0.0.0"
      Capybara.server_port = 4000
      ip = Socket.ip_address_list.detect(&:ipv4_private?).ip_address
      Capybara.app_host = "http://#{ip}:4000"
    else
      Capybara.register_driver(:headless_chrome) do |app|
        Capybara::Selenium::Driver.new(app,
                                       browser: :chrome,
                                       options:)
      end
      driven_by :headless_chrome
    end
  end

  # Gives more verbose output for JS errors, fails any spec with SEVERE errors
  # Based on https://medium.com/@coorasse/catch-javascript-errors-in-your-system-tests-89c2fe6773b1
  config.after(:each, type: :system, js: true) do |example|
    unless ENV["DOCKER_LOCAL_DEV"]
      # Must call page.driver.browser.logs.get(:browser) after every run,
      # otherwise the logs don't get cleared and leak into other specs.
      js_errors = page.driver.browser.logs.get(:browser)
      # Some forms using remote: true return a 406 that is expected
      unless example.metadata[:ignore_js_errors]
        js_errors.each do |error|
          if error.level == "SEVERE" || error.level == "WARNING"
            STDERR.puts "JS error detected (#{error.level}): #{error.message}"
          end
        end
        expect(js_errors.map(&:level)).not_to include "SEVERE"
      end
    end
  end

  Capybara.server = :webrick
  require "capybara/email/rspec"
  Capybara.enable_aria_label = true

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include CapybaraRequests, type: :request
  config.include FactoryBot::Syntax::Methods

  config.around(:each, :feature_setting) do |example|
    example.metadata[:feature_setting].except(:reload_routes).each do |feature, value|
      Settings.feature[feature] = value
    end

    Nucore::Application.reload_routes! if example.metadata[:feature_setting][:reload_routes]

    example.call

    Settings.reload!
    Nucore::Application.reload_routes! if example.metadata[:feature_setting][:reload_routes]
  end

  config.around(:each, :perform_enqueued_jobs) do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  config.around(:each, :ldap) do |example|
    User.define_method(:valid_ldap_authentication?) { |password| password == "netidpassword" }

    example.call

    User.remove_method(:valid_ldap_authentication?)
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

  config.before(:all) do
    # users are not created within transactions, so delete them all here before running tests
    PriceGroupMember.delete_all
    UserRole.delete_all
    User.delete_all
    OrderStatus.delete_all

    # initialize order status constants
    OrderStatus.find_or_create_by(name: "New")
    OrderStatus.find_or_create_by(name: "In Process")
    OrderStatus.find_or_create_by(name: "Canceled")
    OrderStatus.find_or_create_by(name: "Complete")
    OrderStatus.find_or_create_by(name: "Reconciled")
    OrderStatus.find_or_create_by(name: "Unrecoverable")

    # initialize affiliates
    Affiliate.OTHER

    # initialize price groups
    @nupg = PriceGroup.setup_global(name: Settings.price_group.name.base, is_internal: true, display_order: 1)
    PriceGroup.setup_global(name: Settings.price_group.name.external, is_internal: false, display_order: 3)

    # Because many specs rely on not crossing a fiscal year boundary we lock the
    # time globally. Rails's `travel_to` helper does not work well with nesting, so
    # we should use our own custom `travel_and_return` and `travel_to_and_return`
    # helpers. See TimeTravelHelpers. You can also use the spec_helper-defined
    # :time_travel metadata tag.
    travel_back
    now = (SettingsHelper.fiscal_year_beginning(Date.today) + 1.year + 10.days).change(hour: 9, min: 30)
    travel_to(now, safe: true)
  end

  # Allow specififying a Timezone for a group of tests:
  # describe "in central", time_zone: "America/Chicago" do
  config.around(:each, :time_zone) do |example|
    Time.use_zone(example.metadata[:time_zone]) { example.call }
  end

  config.after(:all) { travel_back }

  # Javascript specs need to be able to talk to localhost
  config.around(:each, :js) do |example|
    if ENV["DOCKER_LOCAL_DEV"]
      # As a workaround for https://github.com/bblimke/webmock/issues/1014,
      # we disable WebMock completely for specs run locally within docker.
      WebMock.disable!
      example.call
      WebMock.enable!
      WebMock.disable_net_connect!
    else
      WebMock.disable_net_connect!(allow_localhost: true)
      example.call
      WebMock.disable_net_connect!(allow_localhost: false)
    end
  end

  # Selenium needs to clean itself up once all the tests have been run
  config.after(:all) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  config.before :each, :use_test_account do
    allow(AccountValidator::ValidatorFactory).to(
      receive(:instance) do |account_number, *args|
        if account_number.start_with?(TestAccount::NUMBER_PREFIX)
          TestAccountValidator.new(account_number, *args)
        else
          AccountValidator::ValidatorFactory.validator_class.new(account_number, *args)
        end
      end
    )
  end

  config.around :each, :use_test_account do |example|
    test_view_path = Rails.root.join("spec/support/views")
    view_paths_before = ApplicationController.view_paths

    ApplicationController.append_view_path test_view_path

    example.run

    ApplicationController.view_paths = view_paths_before
  end

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

  require "text_helpers/rspec"

  config.include TextHelpers::RSpec::TestHelpers, locales: true

  config.before(:suite) do
    TextHelpers::RSpec.setup_spec_translations
  end

  config.after(:each, :locales) do
    TextHelpers::RSpec.reset_spec_translations
  end

  def facilities_route
    I18n.t("facilities_downcase")
  end

  config.include Warden::Test::Helpers, type: :system
  config.after type: :system do
    Warden.test_reset!
  end

  config.before type: :system do
    clear_enqueued_jobs
  end

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

  require "rspec/active_job"
  config.include(RSpec::ActiveJob)
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
