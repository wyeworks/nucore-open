# frozen_string_literal: true

class GlobalSearchController < ApplicationController
  skip_before_action :authenticate_user!

  customer_tab :all

  def self.searcher_classes
    @searcher_classes ||=
      [
        GlobalSearch::OrderSearcher,
        GlobalSearch::StatementSearcher,
        GlobalSearch::ProductSearcher,
        GlobalSearch::ProjectSearcher,
      ]
  end

  def index
    @searchers = if user_signed_in? && !acting_as?
                   self.class.searcher_classes.map do |searcher_class|
                     searcher_class.new(acting_user, current_facility, params[:search])
                   end
                 else
                   [GlobalSearch::ProductSearcher.new(acting_user, current_facility, params[:search])]
                 end
  end

end
