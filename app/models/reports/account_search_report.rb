# frozen_string_literal: true

module Reports

  class AccountSearchReport

    include Reports::CsvExporter

    attr_reader :search_term, :facility, :filter_params

    def initialize(search_term:, facility:, filter_params:)
      @search_term = search_term
      @facility = facility
      @filter_params = filter_params
    end

    def report_data_query
      @report_data_query ||= account_searcher.results
    end

    def account_searcher
      AccountSearcher.new(
        search_term,
        scope: Account.for_facility(facility),
        filter_params:,
      )
    end

    def filename
      "accounts.csv"
    end

    def description
      I18n.t("views.account_search_result_mailer.search_result.subject")
    end

    private

    def default_report_hash
      {
        account: :to_s,
        account_number: :account_number,
        description: :description,
        facilities: ->(account) { show_facilities(account) },
        suspended_at: ->(account) { format_usa_date(account.suspended_at) },
        owner: ->(account) { account.owner_user.to_s },
        expires_at: ->(account) { format_usa_date(account.expires_at) },
      }
    end

    def column_headers
      report_hash.keys.map do |field|
        if field == :account
          Account.model_name.human
        else
          Account.human_attribute_name(field)
        end
      end
    end

    def show_facilities(account)
      account.facilities.present? ? account.facilities.join(", ") : I18n.t("shared.all")
    end
  end

end
