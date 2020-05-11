module FullTextSearch

  module Model

    extend ActiveSupport::Concern

    mattr_accessor :full_text_searcher do
      if Nucore::Database.mysql?
        FullTextSearch::MysqlSearcher
      elsif Nucore::Database.oracle?
        FullTextSearch::OracleSearcher
      else
        FullTextSearch::LikeSearcher
      end
    end

    included do
      if Nucore::Database.oracle?
        has_context_index
      end
      scope :full_text, ->(fields, query) { FullTextSearch::Model.full_text_searcher.new(self).search(fields, query) }
    end

  end

end
