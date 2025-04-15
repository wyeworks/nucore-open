# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Viewing estimates", :disable_requests_local do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let(:admin) { create(:user, :facility_administrator, facility:) }
  let(:billing_admin) { create(:user, :global_billing_administrator) }
  let(:senior_staff) { create(:user, :senior_staff, facility:) }
  let(:staff) { create(:user, :staff, facility:) }
  let(:regular_user) { create(:user) }

  let!(:estimate1) { create(:estimate, facility:, name: "First Estimate", created_at: 2.days.ago) }
  let!(:estimate2) { create(:estimate, facility:, name: "Second Estimate", created_at: 1.day.ago) }

  context "viewing index page" do
    context "as authorized roles" do
      shared_examples "can view the estimates index and details" do
        it "displays the list of estimates in order" do
          visit facility_estimates_path(facility)

          expect(page).to have_selector("#admin_estimates_tab")
          expect(page).to have_content "Second Estimate"
          expect(page).to have_content "First Estimate"

          # Newest first
          expect(page.body.index("Second Estimate")).to be < page.body.index("First Estimate")

          click_link estimate1.id

          expect(page).to have_content "Estimate ##{estimate1.id}"
          expect(page).to have_content estimate1.name
          expect(page).to have_content estimate1.user.full_name
          expect(page).to have_content estimate1.created_by_user.full_name
          expect(page).to have_content estimate1.note
          expect(page).to have_content I18n.l(estimate1.expires_at.to_date, format: :usa)
        end
      end

      context "as facility director" do
        before { login_as director }
        include_examples "can view the estimates index and details"
      end

      context "as facility administrator" do
        before { login_as admin }
        include_examples "can view the estimates index and details"
      end

      context "as global billing admin" do
        before { login_as billing_admin }
        include_examples "can view the estimates index and details"
      end
    end

    context "as unauthorized roles" do
      shared_examples "cannot view the estimates index" do
        it "denies access to the estimates page" do
          visit facility_estimates_path(facility)
          expect(page).to have_content "403 – Permission Denied"
          expect(page).to have_content "Sorry, you don't have permission to access this page."
        end
      end

      context "as facility senior staff" do
        before { login_as senior_staff }
        include_examples "cannot view the estimates index"
      end

      context "as facility staff" do
        before { login_as staff }
        include_examples "cannot view the estimates index"
      end

      context "as regular user" do
        before { login_as regular_user }
        include_examples "cannot view the estimates index"
      end
    end
  end

  context "viewing show page" do
    context "as unauthorized roles" do
      shared_examples "cannot view the estimate details" do
        it "denies access to the estimate details" do
          visit facility_estimate_path(facility, estimate1)
          expect(page).to have_content "403 – Permission Denied"
          expect(page).to have_content "Sorry, you don't have permission to access this page."
        end
      end

      context "as facility senior staff" do
        before { login_as senior_staff }
        include_examples "cannot view the estimate details"
      end

      context "as facility staff" do
        before { login_as staff }
        include_examples "cannot view the estimate details"
      end

      context "as regular user" do
        before { login_as regular_user }
        include_examples "cannot view the estimate details"
      end
    end
  end
end
