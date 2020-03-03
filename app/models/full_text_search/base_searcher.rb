module FullTextSearch

  class BaseSearcher

    def initialize(scope)
      @scope = scope
    end

    def arel_table
      @scope.model.arel_table
    end

    def search(fields, query)
      raise NotImplementedError
    end

  end

end
