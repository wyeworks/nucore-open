# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Editing a Service" do
  let(:facility) { create :setup_facility }
  let(:service) { create :service, facility: }
  let(:admin) { create :user, :administrator }

  before do
    login_as admin
  end

  it "can edit a service" do
    visit edit_facility_service_path(facility, service)

    fill_in "service[description]", with: "Some description"
    click_button "Save"

    expect(current_path).to eq(manage_facility_service_path(facility, Service.last))
    expect(page).to have_content("Some description")
  end

  describe "sanger enable change" do
    it "does not show sanger enable if facility is not sanger enabled" do
      facility.update(sanger_sequencing_enabled: false)

      visit edit_facility_service_path(facility, service)

      expect(page).to_not have_field("service[sanger_sequencing_enabled]")
    end

    context "when facility is sanger enabled" do
      before do
        facility.update(sanger_sequencing_enabled: true)
      end

      it "can enable sanger for the service" do
        visit edit_facility_service_path(facility, service)

        check "service[sanger_sequencing_enabled]"
        click_button "Save"

        expect(page).to have_content("Service was successfully updated")
        expect(page).to have_content("Sanger has been enabled")
      end

      it "can disable sanger for the service" do
        service.update(sanger_sequencing_enabled: true)
        visit edit_facility_service_path(facility, service)

        uncheck "service[sanger_sequencing_enabled]"
        click_button "Save"

        expect(page).to have_content("Service was successfully updated")
        expect(page).to have_content("Sanger has been disabled")
      end
    end
  end
end
