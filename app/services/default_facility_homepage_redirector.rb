# frozen_string_literal: true

class DefaultFacilityHomepageRedirector

  def self.redirect_path(facility, user)
    if granular_permissions_only?(user, facility)
      Rails.application.routes.url_helpers.facility_facility_users_path(facility)
    elsif facility.instruments.active.any?
      Rails.application.routes.url_helpers.timeline_facility_reservations_path(facility)
    else
      Rails.application.routes.url_helpers.facility_orders_path(facility)
    end
  end

  # Returns true if the user has no facility role but has an implemented granular permission.
  # Update the `exists?` conditions as new granular permissions are implemented.
  def self.granular_permissions_only?(user, facility)
    return false unless SettingsHelper.feature_on?(:granular_permissions)
    return false if user.administrator?

    !UserRole.exists?(user: user, facility: facility) &&
      user.facility_user_permissions.exists?(facility: facility, assign_permissions: true)
  end

end
