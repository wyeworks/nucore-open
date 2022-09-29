# frozen_string_literal: true

module TransactionSearch

  class StatementSearcher < BaseSearcher

    def options
      # Uses a subquery: SELECT "STATEMENTS".* FROM "STATEMENTS"
      # WHERE "STATEMENTS"."ID" IN (SELECT DISTINCT "ORDER_DETAILS"."STATEMENT_ID" FROM "ORDER_DETAILS" ...
      Statement.where(id: order_details.distinct.select(:statement_id)).reorder(:account_id, :id)
    end

    def search(params)
      if params.present?
        order_details.where(statement_id: params)
      else
        order_details
      end
    end

    def label_method
      :invoice_number
    end

    def label
      I18n.t("Statements")
    end
  end

end
