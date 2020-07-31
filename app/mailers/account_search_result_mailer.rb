# frozen_string_literal: true

class AccountSearchResultMailer < ApplicationMailer

  def search_result(to_email, search_term, facility)
    accounts = AccountSearcher.new(search_term, scope: Account.for_facility(facility)).results
    attachments["accounts.csv"] = Reports::AccountSearchCsv.new(accounts).to_csv
    mail(to: to_email, subject: text("views.account_search_result_mailer.search_result.subject"))
  end

end
