# frozen_string_literal: true

module GrantedPermissionAuthorization

  extend ActiveSupport::Concern

  included do
    helper_method :has_granted_permission?
  end

  private

  def authorize_granted_permission!(permission)
    return if current_user&.administrator?

    granted = current_user&.facility_user_permissions&.find_by(facility: current_facility)

    raise CanCan::AccessDenied unless granted&.public_send(permission)
  end

  def has_granted_permission?(permission)
    return true if current_user&.administrator?
    return false unless current_user

    granted = current_user.facility_user_permissions.find_by(facility: current_facility)
    granted&.public_send(permission) || false
  end

end
