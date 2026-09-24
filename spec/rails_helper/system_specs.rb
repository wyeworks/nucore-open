# frozen_string_literal: true

require "webmock/rspec"

RSpec.configure do |config|
  config.include WaitForHelpers
  config.include SelectFromChosen

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
  Capybara.disable_animation = true
  require "capybara/email/rspec"
  Capybara.enable_aria_label = true

  config.include Warden::Test::Helpers, type: :system
  config.after type: :system do
    Warden.test_reset!
  end

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
end
