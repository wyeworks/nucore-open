# frozen_string_literal: true

module FacilityUserPermissionsHelper

  def permission_summary(permission)
    active = sorted_permissions.select { |perm| permission.public_send(perm) }
    active.map do |perm|
      FacilityUserPermission.human_attribute_name(perm)
    end.join(", ")
  end

  def sorted_permissions
    FacilityUserPermission.all_permissions.sort_by do |perm|
      [perm == :read_access ? 0 : 1, FacilityUserPermission.human_attribute_name(perm)]
    end
  end

  def permission_checkbox_classes(perm)
    return "js--readAccessCheckbox" if perm == :read_access

    classes = ["js--otherPermissionCheckbox"]
    classes << "js--#{perm.to_s.camelize(:lower)}Checkbox" if %i[product_creation product_edition].include?(perm)
    classes.join(" ")
  end

end
