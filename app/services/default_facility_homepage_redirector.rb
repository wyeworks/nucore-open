# frozen_string_literal: true

class DefaultFacilityHomepageRedirector

  def self.redirect_path(facility, _user)
    if facility.instruments.active.any?
      Rails.application.routes.url_helpers.timeline_facility_reservations_path(facility)
    else
      Rails.application.routes.url_helpers.facility_orders_path(facility)
    end
  end

end
