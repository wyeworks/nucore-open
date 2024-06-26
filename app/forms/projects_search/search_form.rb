# frozen_string_literal: true

module ProjectsSearch

  class SearchForm

    include ActiveModel::Model

    attr_accessor :actives, :cross_cores, :current_facility_id

    def self.model_name
      ActiveModel::Name.new(self, nil, "Search")
    end

    def initialize(params, defaults: default_params)
      # If defaults are given, they are merged with the default_params (so we have
      # everything needed, even if the provided defaults are missing one of our
      # defaults.
      full_defaults = defaults.reverse_merge(default_params)
      # okay to use to_unsafe_h here because we are not persisting anything (just a search form)
      super(full_defaults.merge(params&.to_unsafe_h || {}))
    end

    def [](field)
      if field == :date_ranges
        date_params
      else
        public_send(field)
      end
    end

    private

    def default_params
      {}
    end

  end

end
