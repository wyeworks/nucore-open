# frozen_string_literal: true

module AbilityHelper

  # A convenience method to help clarify permissions for various user roles.
  # Useful for developer debugging, this method is not actually invoked anywhere.
  #
  # [_users_]
  #   A collection of User objects to test.
  # [_resource_]
  #   A class or instance that each +user+ will be authorized against.
  # [_controller_]
  #   The controller whose authorization request is being handled.
  #
  # Example usage:
  # check_permissions_for(users: User.all, resource: Facility.last, actions: [:edit, :deactivate], controller: UsersController.new)
  def check_permissions_for(users: User.all, resource: Facility.last, actions: [], controller: nil)
    results = {}
    users.each do |user|
      user_data = []
      user_data << "User #{user.id}:"
      user_data << "Roles: #{user.user_roles.map(&:role)}"
      ability = Ability.new(user, resource, controller)
      actions.each { |action| user_data << "Can #{action}: #{ability.can?(action, resource)}" }
      results[user.last_name] = user_data
    end
    results
  end

end
