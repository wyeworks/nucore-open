# frozen_string_literal: true

class AccountSearchResultMailer < ApplicationMailer

  def search_result(to_email, search_term, facility, filter_params: {})
    scope = Account.for_facility(facility)
    accounts = if search_term.blank?
                 AccountSearcher.new("", scope:, filter_params:).filtered_scope.includes(:owner, :owner_user).order(:type, :account_number)
               else
                 AccountSearcher.new(search_term, scope:, filter_params:).results
               end
    attachments["accounts.csv"] = Reports::AccountSearchCsv.new(accounts).to_csv
    mail(to: to_email, subject: text("views.account_search_result_mailer.search_result.subject"))
  end

end
