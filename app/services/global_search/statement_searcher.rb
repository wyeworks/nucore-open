module GlobalSearch

  class StatementSearcher < Base

    def template
      "statements"
    end

    private

    def search
      return [] unless Account.config.statements_enabled? && query.present?
      Array(Statement.find_by_invoice_number(query.sub(/\A#/, "")))
    end

    def restrict(statements)
      statements.select do |statement|
        abilities(statement).any? { |ability| ability.can?(:show, statement) }
      end
    end

    # Account owners & business admins get their abilities through the account,
    # while facility staff get theirs through the facility, so we need to check
    # both.
    def abilities(statement)
      [
        Ability.new(user, statement.facility),
        Ability.new(user, statement.account),
      ]
    end

  end

end
