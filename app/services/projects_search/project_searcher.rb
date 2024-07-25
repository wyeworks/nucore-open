# frozen_string_literal: true

module ProjectsSearch

  class ProjectSearcher < TransactionSearch::BaseSearcher

    def self.key
      :projects
    end

    def options
      Project.where(id: order_details.select("distinct project_id")).order(:name)
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
