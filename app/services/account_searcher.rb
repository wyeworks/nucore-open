# frozen_string_literal: true

class AccountSearcher

  MINIMUM_SEARCH_LENGTH = 3

  include SearchHelper

  def initialize(original_scope, query)
    @original_scope = original_scope
    @query = query
  end

  def valid?
    @query.to_s.length >= MINIMUM_SEARCH_LENGTH
  end

  def results
    owner_where_clause = <<-end_of_where
      (
        LOWER(users.first_name) LIKE :term
        OR LOWER(users.last_name) LIKE :term
        OR LOWER(users.username) LIKE :term
        OR LOWER(CONCAT(users.first_name, users.last_name)) LIKE :term
      )
      AND account_users.user_role = :acceptable_role
      AND account_users.deleted_at IS NULL
    end_of_where

    term = generate_multipart_like_search_term(@query)

    # retrieve accounts matched on user for this facility
    results = @original_scope.joins(account_users: :user).where(
      owner_where_clause,
      term: term,
      acceptable_role: "Owner",
    ).order("users.last_name, users.first_name")

    # retrieve accounts matched on account_number for this facility
    results += @original_scope.where(
      "LOWER(account_number) LIKE ?", term)
                        .order("type, account_number",
                              )

    results.uniq
  end

end
