module FullTextSearch

  class MysqlSearcher < BaseSearcher

    def initialize(scope)
      @scope = scope
    end

    def search(fields, query)
      full_fields = Array(fields).map { |field| "#{arel_table.name}.#{field}" }.join(", ")
      @scope.where("MATCH(#{full_fields}) AGAINST (?)", query)
    end

  end

end
