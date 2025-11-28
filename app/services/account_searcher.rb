# frozen_string_literal: true

class AccountSearcher

  MINIMUM_SEARCH_LENGTH = 3

  include SearchHelper

  def initialize(query, scope: Account.all, filter_params: {})
    @query = query
    @scope = apply_account_filters(scope, filter_params)
  end

  def valid?
    @query.to_s.length >= MINIMUM_SEARCH_LENGTH
  end

  def results
    matches_owner
      .or(matches_field(:account_number, :description, :ar_number))
      .order(:type, :account_number)
  end

  def filtered_scope
    @scope
  end

  def apply_account_filters(scope, filter_params)
    return scope if SettingsHelper.feature_off?(:account_tabs)

    if filter_params[:account_type].present?
      scope = scope.where(type: filter_params[:account_type])
    end

    if filter_params[:suspended] == "true"
      scope.suspended
    elsif filter_params[:account_status] == "active"
      scope.active
    elsif filter_params[:account_status] == "expired"
      scope.expired.not_suspended
    else
      scope.not_suspended
    end
  end

  private

  def matches_owner
    where_clause = <<~SQL
      LOWER(users.first_name) LIKE :term
      OR LOWER(users.last_name) LIKE :term
      OR LOWER(users.username) LIKE :term
      OR LOWER(CONCAT(users.first_name, users.last_name)) LIKE :term
    SQL

    base_scope.where(
      where_clause,
      term: like_term,
    )
  end

  def matches_field(*fields)
    fields.map do |field|
      # All scopes must have equivalent structures for ActiveRecord's OR to work
      base_scope.where(Account.arel_table[field].lower.matches(like_term))
    end.inject(&:or)
  end

  # The @query, stripped of surrounding whitespace and wrapped in "%"
  def like_term
    generate_multipart_like_search_term(@query)
  end

  def base_scope
    @scope.joins(account_users: :user).merge(AccountUser.owners)
  end

end
