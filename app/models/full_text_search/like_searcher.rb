module FullTextSearch

  # This is intended as a fallback in case NUcore does not have full-text integration
  # with the database
  class LikeSearcher < BaseSearcher

    def search(fields, query)
      query_string = "%#{query.downcase}%"
      searches = Array(fields).map { |field| arel_table[field].lower.matches(query_string) }.inject(&:or)
      @scope.where(searches)
    end

  end

end
