# frozen_string_literal: true

require "rails_helper"

RSpec.describe "product survey page" do
  let(:service) { create(:setup_service) }
  let(:facility) { service.facility }
  let(:user) { create(:user) }

  before do
    user.facility_user_permissions.create(
      facility:, read_access: true,
    )

    login_as user
  end

  context "when user does not have product management permission" do
    it "does not see survey or template forms" do
      visit product_survey_url(facility, service.model_name.plural, service)

      expect(page).not_to have_css("form#new_url_service")
      expect(page).not_to have_css("form#new_stored_file")
    end
  end

  context "when user has product management permission" do
    before do
      FacilityUserPermission
        .where(user:, facility:)
        .update_all(product_management: true)
    end

    it "sees survey and template forms" do
      visit product_survey_url(facility, service.model_name.plural, service)

      expect(page).to have_css("form#new_url_service")
      expect(page).to have_css("form#new_stored_file")
    end
  end
end
