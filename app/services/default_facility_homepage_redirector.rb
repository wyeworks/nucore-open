# frozen_string_literal: true

class DefaultFacilityHomepageRedirector

  # Maps each implemented permission to its landing path method.
  # Order matters — first match wins for dashboard redirect.
  # Add new permissions here as they are implemented.
  PERMISSION_LANDING_PATHS = [
    [:assign_permissions, :facility_facility_users_path],
    [:billing_send, :facility_transactions_path],
    [:billing_journals, :facility_transactions_path],
    # [:product_management, :facility_products_path],
    # [:order_management, :facility_orders_path],
    # [:instrument_management, :timeline_facility_reservations_path],
    # [:product_pricing, :facility_products_path],
    # [:price_adjustment, :facility_orders_path],
  ].freeze

  IMPLEMENTED_PERMISSIONS = PERMISSION_LANDING_PATHS.map(&:first).freeze

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
          .where(IMPLEMENTED_PERMISSIONS.map { |p| "#{p} = TRUE" }.join(" OR "))
          .exists?
  end

  def self.granted_permission_landing_path(facility, user)
    routes = Rails.application.routes.url_helpers
    permission = user.facility_user_permissions.find_by(facility:)
    return routes.facility_path(facility) unless permission

    PERMISSION_LANDING_PATHS.each do |flag, path_method|
      return routes.send(path_method, facility) if permission.send("#{flag}?")
    end

    routes.facility_path(facility)
  end

end
