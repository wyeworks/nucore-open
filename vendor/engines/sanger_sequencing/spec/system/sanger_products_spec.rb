# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sanger Products", feature_setting: { sanger_enabled_service: true } do
  let(:facility) { create(:setup_facility, sanger_sequencing_enabled: true) }
  let(:service) { create(:setup_service, facility:, sanger_sequencing_enabled: true) }
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

    context "when logged in as facility admin" do
      before { login_as admin }

      it "requires the facility to be sanger enabled" do
        facility.update(sanger_sequencing_enabled: false)

        visit facility_service_sanger_sequencing_sanger_product_path(facility, service)

        expect(page).to have_content("Not Found")
      end

      it "does not show the tab if service is sanger disabled" do
        service.update(sanger_sequencing_enabled: false)

        visit facility_service_sanger_sequencing_sanger_product_path(facility, service)

        within(".nav-tabs") do
          expect(page).to_not have_content("Sanger")
        end
      end

      it "shows the tab if service is sanger enabled" do
        visit facility_service_sanger_sequencing_sanger_product_path(facility, service)

        within(".nav-tabs") do
          expect(page).to have_content("Sanger")
        end
      end
    end
  end

  describe "sanger product show" do
    before { login_as admin }

    it "can navigate by clicking the tab" do
      visit manage_facility_service_path(facility, service)

      within(".nav-tabs") do
        click_link("Sanger")
      end

      expect(page).to have_content("Sanger Configuration")
    end

    it "shows sanger product information" do
      visit facility_service_sanger_sequencing_sanger_product_path(facility, service)

      expect(page).to have_content("Sanger Configuration")
      expect(page).to have_content("Needs a Primer")
      expect(page).to have_content("Plated Service Type")
      expect(page).to have_link("Edit")
    end

    it "allows to edit sanger product" do
      visit facility_service_sanger_sequencing_sanger_product_path(facility, service)

      click_link("Edit")

      check("sanger_sequencing_sanger_product[needs_primer]")
      select("Fragment Analysis", from: "sanger_sequencing_sanger_product[group]")

      click_button("Save")

      expect(page).to have_content("Sanger Configuration updated successfully")
    end
  end
end
