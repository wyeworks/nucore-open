# frozen_string_literal: true

class StatementSearchResultMailer < CsvReportMailer

  def search_result(to_email, search_params)
    search_form = StatementSearchForm.new(search_params)
    statements = search_form.search.order(created_at: :desc)

    attachments["statements.csv"] = Report.new(statements).to_csv
    mail(to: to_email, subject: text("views.statement_search_result_mailer.search_result.subject"))
  end

  class Report

    include DateHelper
    include ActionView::Helpers::NumberHelper

    def initialize(statements)
      @statements = statements
    end

    def to_csv
      CSV.generate do |csv|
        csv << headers
        @statements.each do |statement|
          csv << build_row(statement)
        end
      end
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
