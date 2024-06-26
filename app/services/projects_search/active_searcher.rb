# frozen_string_literal: true

module ProjectsSearch

  class ActiveSearcher < BaseSearcher
    def options
      ["active", "inactive"]
    end

    def search(params)
      if params == "inactive"
        projects.inactive
      else
        projects.active
      end
    end

    def label_method
      :humanize
    end

    def label
      I18n.t("projects.index.active_searcher.label")
    end

    def input_type
      :select
    end

  end

end
