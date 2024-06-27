# frozen_string_literal: true

module ProjectsSearch

  class Searcher

    # Do not modify this array directly. Use `ProjectsSearch.register` instead.
    # There is some additional setup that needs to happen (adding an attr_accessor
    # to SearchForm) that `register` handles.
    cattr_accessor(:default_searchers) do
      [
        # CrossCoreSearcher goes first as it is the one that defines the initial projects
        ProjectsSearch::CrossCoreSearcher,
        ProjectsSearch::ActiveSearcher,
      ]
    end

    # Shorthand method if you only want the default searchers
    def self.search(projects, params)
      new.search(projects, params)
    end

    # Expects an array of `ProjectsSearch::BaseSearcher`s
    def initialize(*searchers)
      searchers = self.class.default_searchers if searchers.blank?
      @searchers = Array(searchers)
    end

    def search(projects, params)
      @searchers.reduce(Results.new(projects)) do |results, searcher_class|
        searcher = searcher_class.new(results.projects, params[:current_facility_id])

        search_params = params[searcher_class.key.to_sym]

        # Options should not be restricted, they should search over the full list of projects
        option_searcher = searcher_class.new(projects)

        Results.new(
          searcher.search(search_params),
          results.options + [option_searcher],
        )
      end
    end

    private

    class Results

      attr_reader :projects

      # Return an array of options for a given key
      delegate :[], to: :to_options_by_searcher

      def initialize(projects, search_options = [])
        @projects = projects
        @search_options = search_options.freeze
      end

      def options
        @search_options.dup
      end

      def to_options_by_searcher
        @to_h ||= options.each_with_object({}) do |searcher, hash|
          hash[searcher.key] = searcher.options
        end
      end

    end

  end

end
