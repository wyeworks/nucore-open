# frozen_string_literal: true

module Reports

  class AccountSearchCsv

    include Reports::CsvExporter

    def initialize(accounts)
      @accounts = accounts
    end

    def report_data_query
      @accounts
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
      account.facilities.any? ? account.facilities.join(", ") : I18n.t("shared.all")
    end
  end

end
