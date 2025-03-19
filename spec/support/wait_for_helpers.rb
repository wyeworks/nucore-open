# frozen_string_literal: true

module WaitForHelpers

  def wait_for(timeout = nil, &block)
    return if block.nil?

    Timeout.timeout(timeout.nil? ? Capybara.default_max_wait_time : timeout) do
      loop until yield
    end
  rescue Timeout::Error
    raise "Timeout waiting for condition"
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script("jQuery.active").zero?
  end

end
