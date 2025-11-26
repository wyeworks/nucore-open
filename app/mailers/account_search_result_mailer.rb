# frozen_string_literal: true

class AccountSearchResultMailer < ApplicationMailer

  include AccountScopeFiltering

  def search_result(to_email, search_term, facility, filter_params: {})
    scope = build_account_scope(facility, filter_params)
    accounts = if search_term.blank?
                 scope.includes(:owner, :owner_user).order(:type, :account_number)
               else
                 AccountSearcher.new(search_term, scope:).results
               end
    attachments["accounts.csv"] = Reports::AccountSearchCsv.new(accounts).to_csv
    mail(to: to_email, subject: text("views.account_search_result_mailer.search_result.subject"))
  end

  private

  def build_account_scope(facility, filter_params)
    scope = Account.for_facility(facility)
    apply_account_filters(scope, filter_params)
  end

end
