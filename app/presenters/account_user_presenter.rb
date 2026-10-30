# frozen_string_literal: true

class AccountUserPresenter < SimpleDelegator
  def self.localized_role(role)
    I18n.t(role.downcase.parameterize.underscore, scope: "accounts.role")
  end

  def self.selectable_user_roles(granting_user = nil, facility = nil)
    AccountUser.selectable_user_roles(granting_user, facility).map { |role| [localized_role(role), role] }
  end

  def localized_role
    self.class.localized_role(user_role)
  end
end
