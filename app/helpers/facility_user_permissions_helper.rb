# frozen_string_literal: true

module FacilityUserPermissionsHelper

  def permission_summary(permission)
    active = FacilityUserPermission::PERMISSIONS.select { |perm| permission.public_send(perm) }
    active.map { |perm| I18n.t("views.facility_user_permissions.edit.permission_labels.#{perm}") }.join(", ")
  end

end
