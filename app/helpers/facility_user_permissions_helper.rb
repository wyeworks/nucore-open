# frozen_string_literal: true

module FacilityUserPermissionsHelper

  def permission_summary(permission)
    active = FacilityUserPermission::PERMISSIONS.select { |perm| permission.public_send(perm) }
    active.map do |perm|
      FacilityUserPermission.human_attribute_name(perm)
    end.join(", ")
  end

  def permission_checkbox_classes(perm)
    return "js--readAccessCheckbox" if perm == :read_access

    classes = ["js--otherPermissionCheckbox"]
    classes << "js--#{perm.to_s.camelize(:lower)}Checkbox" if %i[product_creation product_edition].include?(perm)
    classes.join(" ")
  end

end
