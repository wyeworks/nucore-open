# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sanger Product" do
  let(:facility) { create(:setup_facility, sanger_sequencing_enabled: true) }
  let(:service) { create(:setup_service, sanger_sequencing_enabled: true) }
  let(:admin) { create(:user, :facility_administrator, facility:) }
  let(:user) { create(:user) }

  describe "admin tab" do
    context "when not logged in" do
      it "redirects to login" do
        visit facility_service_sanger_sequencing_sanger_product_path(facility, service)

        expect(page).to have_content("Login")
        expect(page).to_not have_content("Sanger")
        expect(page).to_not have_content(service.name)
      end
    end

    context "when logged in as normal user" do
      before { login_as user }

      it "renders permission denied" do
        visit facility_service_sanger_sequencing_sanger_product_path(facility, service)

        expect(page).to have_content("Permission Denied")
      end
    end

    context "when logged in as admin" do
      before { login_as admin }

      it "requires the facility to be sanger enabled" do
        facility.update(sanger_sequencing_enabled: false)

        visit facility_service_sanger_sequencing_sanger_product_path(facility, service)

        expect(page).to have_content("Not Found")
      end

      it "shows the tab if service is sanger enabled" do
        service.update(sanger_sequencing_enabled: true)

        visit facility_service_sanger_sequencing_sanger_product_path(facility, service)

        expect(page).to have_content("Sanger")
      end
    end
  end
end
