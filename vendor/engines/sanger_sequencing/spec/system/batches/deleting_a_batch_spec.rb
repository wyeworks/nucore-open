# frozen_string_literal: true

require "rails_helper"
require_relative "../../support/shared_contexts/setup_sanger_service"

RSpec.describe "Deleting a batch" do
  include_context "Setup Sanger Service"

  let!(:purchased_order) { FactoryBot.create(:purchased_order, product: service, account: account) }
  let!(:purchased_order2) { FactoryBot.create(:purchased_order, product: service, account: account) }
  let!(:purchased_submission) { FactoryBot.create(:sanger_sequencing_submission, order_detail: purchased_order.order_details.first, sample_count: 50) }
  let!(:purchased_submission2) { FactoryBot.create(:sanger_sequencing_submission, order_detail: purchased_order2.order_details.first, sample_count: 50) }

  let!(:batch) { FactoryBot.create(:sanger_sequencing_batch, facility: facility, submissions: [purchased_submission, purchased_submission2]) }

  let(:facility_staff) { FactoryBot.create(:user, :staff, facility: facility) }

  before do
    login_as facility_staff
    visit facility_sanger_sequencing_admin_batches_path(facility)
    click_link "Delete"
  end

  it "destroys the batch and nullifies the submissions' batch_id" do
    expect(SangerSequencing::Batch.find_by(id: batch.id)).to be_blank

    expect(purchased_submission.reload.batch_id).to be_blank
    expect(purchased_submission2.reload.batch_id).to be_blank
  end

  it "redirects back to the batches index" do
    expect(current_path).to eq(facility_sanger_sequencing_admin_batches_path(facility))
  end
end
