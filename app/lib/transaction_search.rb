# frozen_string_literal: true

module TransactionSearch

  # Register a TransactionSearch::BaseSearcher. Unless specified otherwise,
  # it will be added to the list of default searchers.
  def self.register(searcher, default: true)
    Searcher.default_searchers << searcher if default
    SearchForm.send(:attr_accessor, searcher.key)
  end

  def self.register_optimizer(optimizer)
    Searcher.optimizers << optimizer
  end

end
