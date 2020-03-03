# frozen_string_literal: true

require "rails_helper"
require_relative "../support/shared_contexts/setup_sanger_service"

RSpec.describe "Sanger Sequencing Administration" do
  include_context "Setup Sanger Service"

  describe "as facility staff" do
    let(:facility_staff) { FactoryBot.create(:user, :staff, facility: facility) }

    before { login_as facility_staff }

    describe "index view" do
      let!(:unpurchased_order) { FactoryBot.create(:setup_order, product: service, account: account) }
      let!(:unpurchased_submission) { FactoryBot.create(:sanger_sequencing_submission, order_detail: unpurchased_order.order_details.first) }
      let!(:purchased_order) { FactoryBot.create(:purchased_order, product: service, account: account) }
      let!(:purchased_submission) { FactoryBot.create(:sanger_sequencing_submission, order_detail: purchased_order.order_details.first) }

      before do
        visit list_facilities_path
        click_link(facility.name, match: :first)
        click_link("Sanger", match: :first)
      end

      it "has only the purchased submission" do
        expect(page).to have_link(purchased_order.order_details.first.to_s)
        expect(page).not_to have_link(unpurchased_order.order_details.first.to_s)
      end

      describe "clicking through to show" do
        before do
          purchased_submission.samples.create(customer_sample_id: "TESTING 123")
          click_link purchased_submission.id.to_s
        end

        it "has the sample on the page" do
          expect(page).to have_content("TESTING 123")
        end
      end

      describe "attempting to access an unpurchased submission" do
        before { visit facility_sanger_sequencing_admin_submission_path(facility, unpurchased_submission) }

        it "is not found" do
          expect(page.status_code).to eq(404)
        end
      end

      describe "accessing via the 'View Order Form' link" do
        let!(:order_detail) { FactoryBot.create(:purchased_order, product: service, account: account).order_details.first }
        let!(:submission) { FactoryBot.create(:sanger_sequencing_submission, order_detail: order_detail) }
        let(:external_service) { FactoryBot.create(:external_service) }
        let!(:receiver) do
          ExternalServiceReceiver.create(
            external_service: external_service,
            receiver: order_detail,
            response_data: { show_url: sanger_sequencing_submission_path(submission) }.to_json,
          )
        end

        before do
          visit facility_orders_path(facility)
          click_link "View Order Form"
        end

        it "can view the submission" do
          expect(page).to have_content "Submission ##{submission.id}"
          expect(current_path).to eq(facility_sanger_sequencing_admin_submission_path(facility, submission))
        end
      end
    end

    describe "if the feature is disabled" do
      before do
        facility.update(sanger_sequencing_enabled: false)
        visit facility_sanger_sequencing_admin_submissions_path(facility)
      end

      it "renders a 404" do
        expect(page.status_code).to eq(404)
      end
    end
  end

  describe "as a member of another facility" do
    let(:facility2) { FactoryBot.create(:facility) }
    let(:other_user) { FactoryBot.create(:user, :staff, facility: facility2) }

    before { login_as other_user }

    it "does not have access" do
      visit facility_sanger_sequencing_admin_submissions_path(facility)
      expect(page.status_code).to eq(403)
    end
  end
end
