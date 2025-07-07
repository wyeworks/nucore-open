# frozen_string_literal: true

module Reports
  class StatementSearchReport
    include DateHelper
    include ActionView::Helpers::NumberHelper
    include TextHelpers::Translation

    attr_reader :raw_search_params

    def initialize(search_params:)
      @raw_search_params = search_params
    end

    def search_params
      @search_params =
        begin
          current_facility = Facility.by_url_name(
            raw_search_params[:current_facility]
          )
          raw_search_params.merge(current_facility:)
        end
    end

    def search_form
      @search_form ||= StatementSearchForm.new(search_params)
    end

    def statements
      @statements ||= search_form.search.order(created_at: :desc)
    end

    def to_csv
      CSV.generate do |csv|
        csv << headers
        statements.each do |statement|
          csv << build_row(statement)
        end
      end
    end

    def has_attachment?
      true
    end

    def filename
      "statements.csv"
    end

    def description
      text("subject")
    end

    def text_content
      text("body")
    end

    def translation_scope
      "views.statement_search_result_mailer.search_result"
    end

    private

    def headers
      [
        Statement.human_attribute_name(:invoice_number),
        Statement.human_attribute_name(:created_at),
        Statement.human_attribute_name(:account_admins),
        Account.model_name.human,
        Facility.model_name.human,
        "# of #{Order.model_name.human.pluralize}",
        Statement.human_attribute_name(:total_cost),
        Statement.human_attribute_name(:status),
      ]
    end

    def build_row(statement)
      [
        statement.invoice_number,
        format_usa_datetime(statement.created_at),
        statement.account.notify_users.map(&:full_name).join(', '),
        statement.account,
        statement.facility,
        statement.order_details.count,
        number_to_currency(statement.total_cost),
        statement.status,
      ]
    end
  end
end
