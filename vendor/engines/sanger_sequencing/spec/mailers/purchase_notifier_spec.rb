require "rails_helper"
require_relative "../support/shared_contexts/setup_sanger_service"

RSpec.describe PurchaseNotifier, type: :mailer do
  include_context "Setup Sanger Service"

  let!(:order) { FactoryBot.create(:purchased_order, product: service, account: account) }
  let(:order_detail) { order.order_details.first }
  let!(:submission) { FactoryBot.create(:sanger_sequencing_submission, order_detail: order_detail, sample_count: 3) }

  let(:external_service) { create(:external_service, location: new_sanger_sequencing_submission_path) }
  let!(:sanger_order_form) { create(:external_service_passer, external_service: external_service, active: true, passer: service) }
  let!(:receiver) do
    ExternalServiceReceiver.create(
      external_service: external_service,
      receiver: order_detail,
      response_data: { show_url: sanger_sequencing_submission_path(submission) }.to_json,
    )
  end
  let(:mailer) { described_class.order_notification(order, order.user) }

  it "includes the samples in the mailer" do
    expect(mailer.body.encoded).to include(submission.samples.first.customer_sample_id)
  end

  describe "when the sample has results" do
    let!(:result) { FactoryBot.create(:stored_file, :results, name: "#{submission.samples.first.id}_test.txt", order_detail: order_detail) }

    it "includes the samples in the mailer" do
      expect(mailer.body.encoded).to include(submission.samples.first.customer_sample_id)
    end
  end

end
