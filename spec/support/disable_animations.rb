# frozen_string_literal: true

# Disable CSS transitions and animations in JS system tests to prevent
# flaky specs caused by Capybara interacting with elements mid-animation
# (e.g., Bootstrap modal fade causing checkbox clicks to miss).
module DisableAnimations

  DISABLE_ANIMATIONS_SCRIPT = <<~JS
    if (!document.getElementById('disable-animations')) {
      var style = document.createElement('style');
      style.id = 'disable-animations';
      style.textContent = '*, *::before, *::after { transition-duration: 0s !important; animation-duration: 0s !important; }';
      document.head.appendChild(style);
    }
  JS

  def visit(*)
    super
    page.execute_script(DISABLE_ANIMATIONS_SCRIPT) if javascript_driver?
  rescue Selenium::WebDriver::Error::JavascriptError, Selenium::WebDriver::Error::NoSuchWindowError
    # Ignore if page is not ready (e.g., redirect in progress)
  end

  private

  def javascript_driver?
    Capybara.current_driver != :rack_test
  end

end

RSpec.configure do |config|
  config.include DisableAnimations, type: :system
end
