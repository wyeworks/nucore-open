# frozen_string_literal: true

module CapybaraRequests

  def page
    Capybara.string(response.body)
  end

end
