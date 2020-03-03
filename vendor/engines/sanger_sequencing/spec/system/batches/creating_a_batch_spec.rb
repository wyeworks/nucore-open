# frozen_string_literal: true

require "rails_helper"
require_relative "../../support/shared_contexts/setup_sanger_service"

RSpec.describe "Creating a batch", :js do
  include_context "Setup Sanger Service"

  let!(:purchased_order) { FactoryBot.create(:purchased_order, product: service, account: account) }
  let!(:purchased_order2) { FactoryBot.create(:purchased_order, product: service, account: account) }
  let!(:purchased_submission) { FactoryBot.create(:sanger_sequencing_submission, order_detail: purchased_order.order_details.first, sample_count: 50) }
  let!(:purchased_submission2) { FactoryBot.create(:sanger_sequencing_submission, order_detail: purchased_order2.order_details.first, sample_count: 50) }

  let(:facility_staff) { FactoryBot.create(:user, :staff, facility: facility) }

  before { login_as facility_staff }

  def click_add(submission_id)
    within("[data-submission-id='#{submission_id}']") do
      click_link "Add"
    end
  end

  describe "creating a well-plate" do
    before do
      visit facility_sanger_sequencing_admin_batches_path(facility)
      click_link "Create New Batch"
    end

    describe "adding both submissions" do
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

  describe "creating a batch with a previously completed submission" do
    let!(:completed_submission) { FactoryBot.create(:sanger_sequencing_submission, order_detail: purchased_order2.order_details.first, sample_count: 50) }

    before do
      purchased_order.order_details.first.to_complete

      visit facility_sanger_sequencing_admin_batches_path(facility)
      click_link "Create New Batch"
      click_add(completed_submission.id)
      click_button "Save Batch"
    end

    it "Saves the batch and takes you to the batches index", :aggregate_failures do
      expect(completed_submission.reload.batch_id).to be_present

      expect(SangerSequencing::Batch.last.sample_at(0, "A01")).to be_reserved
      expect(SangerSequencing::Batch.last.sample_at(0, "B01")).to eq(completed_submission.samples.first)

      expect(current_path).to eq(facility_sanger_sequencing_admin_batches_path(facility))
    end
  end

  describe "creating a fragment analysis well-plate" do
    describe "listing the products" do
      before do
        visit facility_sanger_sequencing_admin_batches_path(facility, group: "fragment")
        click_link "Create New Batch"
      end

      it "does not have the submissions" do
        expect(page).to have_content("There are no submissions available to be added.")
      end
    end

    describe "when the service is mapped to the fragment group" do
      before do
        SangerSequencing::ProductGroup.create!(product: service, group: "fragment")
        visit facility_sanger_sequencing_admin_batches_path(facility, group: "fragment")
        click_link "Create New Batch"
      end

      describe "adding the first submissions" do
        def click_add(submission_id)
          within("[data-submission-id='#{submission_id}']") do
            click_link "Add"
          end
        end

        before do
          click_add(purchased_submission.id)
          click_button "Save Batch"
        end

        it "Saves the batch with no reserved cells", :aggregate_failures do
          expect(purchased_submission.reload.batch_id).to be_present

          expect(SangerSequencing::Batch.last.sample_at(0, "A01")).to eq(purchased_submission.samples.first)
          expect(SangerSequencing::Batch.last.sample_at(0, "B01")).to eq(purchased_submission.samples.second)
          expect(SangerSequencing::Batch.last.sample_at(0, "A02")).to eq(purchased_submission.samples[48])

          expect(SangerSequencing::Batch.last.group).to eq("fragment")
        end
      end
    end
  end
end
