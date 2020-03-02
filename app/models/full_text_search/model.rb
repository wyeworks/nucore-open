module FullTextSearch

  module Model

    extend ActiveSupport::Concern

    mattr_accessor :full_text_searcher do
      if Nucore::Database.mysql?
        FullTextSearch::MysqlSearcher
      else
        FullTextSearch::LikeSearcher
      end
    end

    included do
      scope :full_text, ->(fields, query) { FullTextSearch::Model.full_text_searcher.new(self).search(fields, query) }
    end

  end

end
