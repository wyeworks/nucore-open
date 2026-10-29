# frozen_string_literal: true

class UserPresenter < SimpleDelegator
  include ActionView::Helpers::FormOptionsHelper

  delegate :global, to: :user_roles, prefix: true

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

  # TODO: Existing data may have duplicate roles, thus the "uniq" call.
  # Duplicate UserRoles are invalid so new duplicates should not be possible.
  # It should be safe to remove the "uniq" once the old duplicates are gone.
  def global_roles
    user_roles_global.pluck(:role).uniq
  end
end
