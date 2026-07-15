# frozen_string_literal: true

module FacilityUserPermissionsHelper

  def permission_summary(permission)
    sorted_permissions_with_labels.filter_map do |perm, label|
      label if permission.public_send(perm)
    end.join(", ")
  end

  def sorted_permissions_with_labels
    FacilityUserPermission.all_permissions
                          .map { |perm| [perm, FacilityUserPermission.human_attribute_name(perm)] }
                          .sort_by { |perm, label| [perm == :read_access ? 0 : 1, label] }
  end

  def permission_checkbox_classes(perm)
    return "js--readAccessCheckbox" if perm == :read_access

    classes = ["js--otherPermissionCheckbox"]
    classes << "js--#{perm.to_s.camelize(:lower)}Checkbox" if %i[product_creation product_edition].include?(perm)
    classes.join(" ")
  end

end
