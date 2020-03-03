# frozen_string_literal: true

class UserFinder

  include SearchHelper

  class_attribute :searchable_columns

  self.searchable_columns = [
    "first_name",
    "last_name",
    "username",
    "CONCAT(first_name, last_name)",
    "email",
  ]

  def self.search(search_term, limit = nil)
    if search_term.present?
      new(search_term, limit).result
    else
      [nil, nil]
    end
  end

  def initialize(search_term, limit = nil)
    @search_term = generate_multipart_like_search_term(search_term)
    @limit = limit
  end

  def result
    [users, relation.count]
  end

  private

  def relation
    condition_sql = searchable_columns
                    .map { |column| "LOWER(#{column}) LIKE :search_term" }
                    .join(" OR ")

    @relation ||= User.where(condition_sql, search_term: @search_term)
  end

  def users
    relation.order(:last_name, :first_name).limit(@limit)
  end

end
