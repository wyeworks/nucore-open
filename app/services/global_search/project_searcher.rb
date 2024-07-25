# frozen_string_literal: true

module GlobalSearch

  class ProjectSearcher < ::GlobalSearch::Base

    def template
      "projects"
    end

    private

    def query_object
      if facility.try(:single_facility?)
        facility.projects
      else
        Project
      end
    end

    def restrict(projects)
      projects.select do |project|
        Ability.new(user, project).can?(:show, project)
      end
    end

    def search
      query_object.where("lower(name) LIKE ?", "%#{query.downcase}%").or(Project.where(id: query))
    end

  end

end
