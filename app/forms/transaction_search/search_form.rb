# frozen_string_literal: true

module TransactionSearch

  class SearchForm

    include ActiveModel::Model

    attr_accessor :date_range_field, :date_range_start, :date_range_end, :allowed_date_fields
    attr_accessor :facilities, :accounts, :products, :account_owners,
                  :order_statuses, :statements, :date_ranges, :ordered_fors,
                  :account_types, :cross_cores, :cross_core_facilties,
                  :current_facility_id,
                  :projects,
                  :price_groups

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

    def date_params
      {
        field: date_range_field,
        start: date_range_start,
        end: date_range_end,
      }
    end

    private

    def default_params
      {
        date_range_field: "fulfilled_at",
        allowed_date_fields: TransactionSearch::DateRangeSearcher::FIELDS,
      }
    end

  end

end
