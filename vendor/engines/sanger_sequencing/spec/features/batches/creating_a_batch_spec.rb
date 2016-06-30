require "rails_helper"
require_relative "../../support/shared_contexts/setup_sanger_service"

RSpec.describe "Creating a batch", :js do
  include_context "Setup Sanger Service"

  let!(:purchased_order) { FactoryGirl.create(:purchased_order, product: service, account: account) }
  let!(:purchased_order2) { FactoryGirl.create(:purchased_order, product: service, account: account) }
  let!(:purchased_submission) { FactoryGirl.create(:sanger_sequencing_submission, order_detail: purchased_order.order_details.first, sample_count: 50) }
  let!(:purchased_submission2) { FactoryGirl.create(:sanger_sequencing_submission, order_detail: purchased_order2.order_details.first, sample_count: 50) }

  let(:facility_staff) { FactoryGirl.create(:user, :staff, facility: facility) }

  before { login_as facility_staff }

  describe "creating a well-plate" do
    before do
      visit facility_sanger_sequencing_admin_submissions_path(facility)
      click_link "Create New Batch"
    end

    describe "adding both submissions" do
      def click_add(submission_id)
        within("[data-submission-id='#{submission_id}']") do
          click_link "Add"
        end
      end

      before do
        click_add(purchased_submission.id)
        click_add(purchased_submission2.id)
        click_button "Save Batch"
      end

      it "Saves the batch and takes you to the batches index", :aggregate_failures do
        expect(purchased_submission.reload.batch_id).to be_present
        expect(purchased_submission2.reload.batch_id).to be_present

        expect(SangerSequencing::Batch.last.sample_at(0, "A01")).to be_reserved
        expect(SangerSequencing::Batch.last.sample_at(0, "B01")).to eq(purchased_submission.samples.first)
        expect(SangerSequencing::Batch.last.sample_at(1, "B01")).to eq(purchased_submission2.samples[44])

        expect(current_path).to eq(facility_sanger_sequencing_admin_batches_path(facility))
      end
    end
  end
end
