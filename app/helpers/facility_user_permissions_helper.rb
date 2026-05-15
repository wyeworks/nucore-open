# frozen_string_literal: true

module FacilityUserPermissionsHelper

  def permission_summary(permission)
    active = FacilityUserPermission::PERMISSIONS.select { |perm| permission.public_send(perm) }
    active.map do |perm|
      FacilityUserPermission.human_attribute_name(perm)
    end.join(", ")
  end

  def permission_checkbox_classes(perm)
    classes = [perm == :read_access ? "js--readAccessCheckbox" : "js--otherPermissionCheckbox"]
    classes << "js--productCreationCheckbox" if perm == :product_creation
    classes << "js--productEditionCheckbox" if perm == :product_edition
    classes.join(" ")
  end

end
