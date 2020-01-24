# frozen_string_literal: true

require "rails_helper"
require_relative "../../support/shared_contexts/setup_sanger_service"

RSpec.describe SangerSequencing::BatchForm do
  let(:submission) { FactoryBot.create(:sanger_sequencing_submission, sample_count: 2) }
  let(:submission2) { FactoryBot.create(:sanger_sequencing_submission, sample_count: 3) }

  describe "new" do
    let(:form) { described_class.new }
    before { form.assign_attributes(params) }

    describe "blank" do
      let(:params) { { submission_ids: "" } }

      it "does not allow no submissions" do
        expect(form).to be_invalid
        expect(form.errors).to be_added(:submission_ids, :blank)
      end
    end

    describe "with one submission" do
      describe "with all the samples" do
        let(:params) do
          { submission_ids: submission.id.to_s,
            well_plate_data: { "0" => { "A01" => submission.samples.first.id,
                                        "B02" => submission.samples.second.id } } }
        end

        it "is valid" do
          expect(form).to be_valid
        end
      end
    end

    describe "missing a sample" do
      let(:params) do
        { submission_ids: submission.id.to_s,
          well_plate_data: { "0" => { "A01" => submission.samples.first.id } } }
      end

      it "is invalid" do
        expect(form).to be_invalid
        expect(form.errors).to be_added(:submitted_sample_ids, :must_match_submissions)
      end
    end

    describe "with a sample from the second submission" do
      let(:params) do
        { submission_ids: submission.id.to_s,
          well_plate_data: { "0" => { "A01" => submission.samples.first.id,
                                      "B01" => submission2.samples.first.id } } }
      end

      it "is invalid" do
        expect(form).to be_invalid
        expect(form.errors).to be_added(:submitted_sample_ids, :must_match_submissions)
      end
    end

    describe "adding a submission that is already part of a batch" do
      let!(:batch) { SangerSequencing::Batch.create(submissions: [submission]) }
      let(:params) do
        { submission_ids: submission.id.to_s }
      end

      it "is not valid" do
        expect(form).to be_invalid
        expect(form.errors).to be_added(:submission_ids, :submission_part_of_other_batch, id: submission.id.to_s)
      end
    end

    describe "facility checking" do
      include_context "Setup Sanger Service"

      let!(:purchased_order) { FactoryBot.create(:purchased_order, product: service, account: account) }
      let!(:purchased_order2) { FactoryBot.create(:purchased_order, product: service, account: account) }
      let!(:purchased_submission) { FactoryBot.create(:sanger_sequencing_submission, order_detail: purchased_order.order_details.first, sample_count: 50) }
      let!(:purchased_submission2) { FactoryBot.create(:sanger_sequencing_submission, order_detail: purchased_order2.order_details.first, sample_count: 50) }

      let(:params) do
        { submission_ids: "#{purchased_submission.id},#{purchased_submission2.id}",
          facility: facility }
      end

      describe "when all facilities match" do
        before do
          allow(purchased_submission).to receive(:facility).and_return(facility)
          allow(purchased_submission2).to receive(:facility).and_return(facility)
        end

        it "is valid for facilities" do
          form.valid?
          expect(form.errors).not_to include(:submission_ids)
        end
      end

      describe "when one submission is in another facility" do
        let(:facility2) { FactoryBot.create(:facility) }

        before do
          purchased_submission2.order.update(facility: facility2)
        end

        it "is invalid" do
          expect(form).to be_invalid
          expect(form.errors).to be_added(:submission_ids, :invalid_facility, id: purchased_submission2.id.to_s)
        end
      end
    end
  end
end
