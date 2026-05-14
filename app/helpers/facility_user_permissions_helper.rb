# frozen_string_literal: true

module FacilityUserPermissionsHelper

  def permission_summary(permission)
    active = FacilityUserPermission::PERMISSIONS.select { |perm| permission.public_send(perm) }
    active.map do |perm|
      FacilityUserPermission.human_attribute_name(perm)
    end.join(", ")
  end

end
