# frozen_string_literal: true

module SortableColumnController

  extend ActiveSupport::Concern

  included do
    helper_method :sort_column, :sort_direction
  end

  def sort_clause
    Array(sort_lookup_hash[sort_column]).map do |clause|
      [clause, sort_direction].join(" ")
    end
  end

  private

  def sort_lookup_hash
    raise NotImplementedError
  end

  def sort_direction
    params[:dir] == "desc" ? "desc" : "asc"
  end

  def sort_column
    sort_lookup_hash.key?(params[:sort]) ? params[:sort] : sort_lookup_hash.keys.first
  end

end
