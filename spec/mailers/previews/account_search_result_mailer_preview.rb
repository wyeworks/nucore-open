# frozen_string_literal: true

class AccountSearchResultMailerPreview < ActionMailer::Preview

  def search_result
    AccountSearchResultMailer.search_result("example@example.com", "123", Facility.first)
  end

end
