# frozen_string_literal: true

module TransactionSearch

  class Searcher

    # Do not modify this array directly. Use `TransactionSearch.register` instead.
    # There is some additional setup that needs to happen (adding an attr_accessor
    # to SearchForm) that `register` handles.
    cattr_accessor(:default_searchers) do
      [
        TransactionSearch::FacilitySearcher,
        TransactionSearch::AccountSearcher,
        TransactionSearch::AccountTypeSearcher,
        TransactionSearch::ProductSearcher,
        TransactionSearch::AccountOwnerSearcher,
        TransactionSearch::OrderedForSearcher,
        TransactionSearch::OrderStatusSearcher,
        TransactionSearch::DateRangeSearcher,
        TransactionSearch::CrossCoreSearcher,
        ProjectsSearch::ProjectSearcher,
      ]
    end

    # Prefer `TransactionSearch.register_optimizer` rather than modifying this
    # directly in order to maintain API consistency with `default_searchers`.
    cattr_accessor(:optimizers) do
      [
        TransactionSearch::NPlusOneOptimizer,
      ]
    end

    # Initially all searchers in default_searchers
    # are enabled
    cattr_accessor(:default_enabled) do
      {
        facilities: false,
      }
    end

    # Shorthand method if you only want the default searchers
    def self.search(order_details, params)
      new.search(order_details, params)
    end

    # Expects an array of `TransactionSearch::BaseSearcher`s
    def initialize(*searchers, searchers_opts: {}, **kwargs)
      searchers_enabled = default_enabled.merge(kwargs)

      @searchers_opts = searchers_opts
      @searchers =
        searchers.presence ||
        default_searchers.filter do |searcher_class|
          searchers_enabled.fetch(searcher_class.key.to_sym, true)
        end
    end

    def search(order_details, params)
      order_details = add_global_optimizations(order_details)

      @searchers.reduce(Results.new(order_details)) do |results, searcher_class|
        searcher = searcher_class.new(
          results.order_details,
          params[:current_facility_id],
          **@searchers_opts,
        )
        search_params = params[searcher_class.key.to_sym]
        search_params = Array(search_params).reject(&:blank?) unless searcher.multipart?

        # Options should not be restricted, they should search over the full order details
        option_searcher = searcher_class.new(order_details)

        Results.new(
          searcher.search(search_params),
          results.options + [option_searcher],
        )
      end
    end

    private

    def add_global_optimizations(order_details)
      optimizers.reduce(order_details) do |current, optimizer|
        optimizer.new(current).optimize
      end
    end

    class Results

      attr_reader :order_details

      # Return an array of options for a given key
      delegate :[], to: :to_options_by_searcher

      def initialize(order_details, search_options = [])
        @order_details = order_details
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
