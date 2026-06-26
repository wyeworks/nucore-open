# frozen_string_literal: true

module ProjectsSearch

  class CrossCoreSearcher < BaseSearcher
    def options
      ["no", "yes"]
    end

    def search(params)
      if params == "yes"
        cross_core_projects
      else
        single_facility_projects
      end
    end

    def label_method
      :humanize
    end

    def label
      I18n.t("projects.index.cross_core_searcher.label")
    end

    def input_type
      :select
    end

    private

    def cross_core_projects
      Project.cross_core.for_facility(@current_facility_id).distinct
    end

    def single_facility_projects
      Project.for_single_facility(@current_facility_id)
    end

  end

end
