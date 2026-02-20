# frozen_string_literal: true

class DefaultFacilityHomepageRedirector

  def self.redirect_path(facility, user)
    if granular_permissions_only?(user, facility)
      granted_permission_landing_path(facility, user)
    elsif facility.instruments.active.any?
      Rails.application.routes.url_helpers.timeline_facility_reservations_path(facility)
    else
      Rails.application.routes.url_helpers.facility_orders_path(facility)
    end
  end

  # Returns true if the user has no facility role but has an implemented granular permission.
  def self.granular_permissions_only?(user, facility)
    return false unless SettingsHelper.feature_on?(:granular_permissions)
    return false if user.administrator?

    !UserRole.exists?(user: user, facility: facility) &&
      user.facility_user_permissions
          .where(facility:)
          .where("assign_permissions = TRUE OR billing_send = TRUE")
          .exists?
  end

  def self.granted_permission_landing_path(facility, user)
    routes = Rails.application.routes.url_helpers
    permission = user.facility_user_permissions.find_by(facility:)

    if permission&.assign_permissions?
      routes.facility_facility_users_path(facility)
    elsif permission&.billing_send?
      routes.facility_transactions_path(facility)
    else
      routes.facility_path(facility)
    end
  end

end
