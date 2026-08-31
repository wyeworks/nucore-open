# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FacilityEstimatesController" do
  describe "form facility options" do
    let!(:facility) { create(:setup_facility) }
    let!(:other_facility) { create(:setup_facility) }
    let!(:other_facility2) { create(:setup_facility) }
    let(:action) do
      -> { get new_facility_estimate_path(facility) }
    end

    before { login_as user }

    shared_examples "products from all facilities" do
      it "can see add products from all facilities" do
        action.call

        expect(page).to have_select(
          :facility_id,
          with_options: Facility.alphabetized.pluck(:name),
        )
      end
    end

    shared_examples "products from allowed facilities" do
      it "can select products from allowed facilities" do
        action.call

        expect(page).to have_select(
          :facility_id,
          with_options: [facility.name],
        )
      end
    end

    context "when user globla admin" do
      let(:user) { create(:user, :administrator) }

      include_examples "products from all facilities"
    end

    context "as administrator with user roles" do
      let(:user) { create(:user, :facility_administrator, facility:) }

      include_examples "products from all facilities"
    end

    context "as staff with granular permissions" do
      let(:user) { create(:user) }

      before do
        FacilityUserPermission.create(
          facility:, user:, read_access: true, quoting: true,
        )
      end

      include_examples "products from allowed facilities"
    end

    context "as staff with granular permissions with order management" do
      let(:user) { create(:user) }

      before do
        FacilityUserPermission.create(
          facility:, user:,
          read_access: true,
          quoting: true,
          order_management: true,
        )
      end

      include_examples "products from all facilities"
    end
  end

  describe "show" do
    let(:facility) { create(:setup_facility) }
    let(:estimate) { create(:estimate, facility:) }
    let(:action) do
      -> { get facility_estimate_path(facility, estimate) }
    end

    before { login_as create(:user, :administrator) }

    it "includes download links" do
      action.call

      expect(response).to have_http_status(:ok)
      expect(page).to have_text("Download CSV")
      expect(page).to have_text("Download PDF") if EstimatePdfFactory.defined?
    end

    context "when format is pdf" do
      let(:action) do
        -> { get facility_estimate_path(facility, estimate, format: :pdf) }
      end

      before do
        skip("Estimate Pdf not defined") unless EstimatePdfFactory.defined?
      end

      it "responds with a pdf" do
        action.call

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("application/pdf")
      end
    end
  end
end
