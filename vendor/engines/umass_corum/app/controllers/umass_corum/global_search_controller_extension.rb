# frozen_string_literal: true

module UmassCorum

  module GlobalSearchControllerExtension

    extend ActiveSupport::Concern

    included do
      searcher_classes.unshift(UmassCorum::GlobalSearch::JournalSearcher)
    end

  end

end
