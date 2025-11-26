# frozen_string_literal: true

module AccountScopeFiltering

  private

  def apply_account_filters(scope, filter_params)
    return scope unless SettingsHelper.feature_on?(:account_tabs)

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

end
