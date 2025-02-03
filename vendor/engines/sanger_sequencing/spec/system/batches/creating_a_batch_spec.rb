# frozen_string_literal: true

require "rails_helper"
require_relative "../../support/shared_contexts/setup_sanger_service"

RSpec.describe "Creating a batch", :js, feature_setting: { sanger_sequencing_enabled: false } do
  include_context "Setup Sanger Service"

  let!(:purchased_order) { create(:purchased_order, product: service, account: account) }
  let!(:purchased_order2) { create(:purchased_order, product: service, account: account) }
  let!(:purchased_submission) { create(:sanger_sequencing_submission, order_detail: purchased_order.order_details.first, sample_count: 50) }
  let!(:purchased_submission2) { create(:sanger_sequencing_submission, order_detail: purchased_order2.order_details.first, sample_count: 50) }

  let(:facility_staff) { create(:user, :staff, facility: facility) }

  before { login_as facility_staff }

  def click_add(submission_id)
    within("[data-submission-id='#{submission_id}']") do
      click_link "Add"
    end
  end

  describe "plate column order", feature_setting: { sanger_enabled_service: true } do
    let!(:submission) do
      create(
        :sanger_sequencing_submission,
        order_detail: purchased_order.order_details.first,
        sample_count: 14
      )
    end
    let(:batch) { submission.reload.batch }

    before do
      visit new_facility_sanger_sequencing_admin_batch_path(facility)
    end

    it "can select odd first order" do
      select("Half Plate", from: "batch[column_order]")

      click_add(submission.id)

      click_button "Save Batch"

      expect(batch.sample_at(0, "A01")).to be_reserved
      expect(batch.sample_at(0, "B01")).to eq(submission.samples.first)
      expect(batch.sample_at(0, "B02")).to be_blank
      expect(batch.sample_at(0, "G03")).to eq(submission.samples.last)
    end

    it "can select sequential order" do
      select("Full Plate", from: "batch[column_order]")

      click_add(submission.id)

      click_button "Save Batch"

      expect(batch.sample_at(0, "A01")).to be_reserved
      expect(batch.sample_at(0, "B01")).to eq(submission.samples.first)
      expect(batch.sample_at(0, "H02")).to eq(submission.samples.last)
      expect(batch.sample_at(0, "B03")).to be_blank
    end
  end

  describe "plate reserved cells selection", feature_setting: { sanger_enabled_service: true } do
    let!(:submission) do
      create(
        :sanger_sequencing_submission,
        order_detail: purchased_order.order_details.first,
        sample_count: 14
      )
    end
    let(:batch) { submission.reload.batch }

    it "can select reserved cells" do
      visit new_facility_sanger_sequencing_admin_batch_path(facility)

      expect(page).to have_content("Reserved Cells")

      select_from_chosen("A01", from: "batch[reserved_cells][]")

      click_add(submission.id)

      click_button("Save Batch")

      expect(batch.sample_at(0, "A01")).to be_reserved
    end

    it "can unselect reserved cells" do
      visit new_facility_sanger_sequencing_admin_batch_path(facility)

      expect(page).to have_content("Reserved Cells")

      unselect_from_chosen("A01", from: "batch[reserved_cells][]")

      click_add(submission.id)

      click_button "Save Batch"

      expect(batch.sample_at(0, "A01")).to eq(submission.samples.first)
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
    let!(:completed_submission) { create(:sanger_sequencing_submission, order_detail: purchased_order2.order_details.first, sample_count: 50) }

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
        SangerSequencing::SangerProduct.create!(product: service, group: "fragment")
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
