# frozen_string_literal: true

module ProjectsSearch

  class ProjectSearcher < TransactionSearch::BaseSearcher

    def self.key
      "projects"
    end

    def options
      projects =
        if current_facility.cross_facility?
          Project.all
        else
          project_ids =
            current_facility
            .order_details
            .where.not(project_id: nil)
            .select(:project_id)

          Project.where(id: project_ids)
        end

      projects.order(:name)
    end

    def search(params)
      if params.present?
        order_details.where(project_id: params)
      else
        order_details
      end
    end

    def label
      Project.model_name.human(count: 2)
    end

  end

end
