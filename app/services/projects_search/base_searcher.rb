# frozen_string_literal: true

module ProjectsSearch

  class BaseSearcher

    attr_reader :projects

    def self.key
      to_s.delete_prefix("ProjectsSearch::").delete_suffix("Searcher").pluralize.underscore
    end

    def initialize(projects, current_facility_id = nil)
      @projects = projects
      @current_facility_id = current_facility_id
    end

    def key
      self.class.key
    end

    def label_method
      nil
    end

    def label
      nil
    end

    # `item` will be one element of the collection
    def data_attrs(_item)
      {}
    end

    def options
      raise NotImplementedError
    end

    def search(_params)
      raise NotImplementedError
    end

  end

end
