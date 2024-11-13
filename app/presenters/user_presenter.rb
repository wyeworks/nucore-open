# frozen_string_literal: true

class UserPresenter < SimpleDelegator

  include ActionView::Helpers::FormOptionsHelper

  def self.wrap(users)
    users.map { |user| new(user) }
  end

  def global_role_list
    global_roles.join(", ")
  end

  def global_role_select_options
    options_for_select(UserRole.global_roles, selected: user_roles.map(&:role))
  end

  # pretend to be a User
  def kind_of?(clazz)
    if clazz == User
      true
    else
      super
    end
  end

  private

  def global_roles
    user_roles.pluck(:role) & UserRole.global_roles
  end

end
