# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentIssue do

  describe "validations" do
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:product) }
  end

  describe "send_notification" do
    let(:valid_issue) do
      user = create(:user)
      product = create(:setup_instrument)

      account = create(:setup_account, owner: user)
      order = create(:order, account: account, created_by_user: user, user: user)
      order_detail = create(:order_detail, order: order, product: product)

      described_class.new(user: create(:user), product: product, order_detail: order_detail, message: "Hello")
    end

    it "returns a truthy value" do
      expect(valid_issue.send_notification).to be_truthy
    end

    it "triggers an email" do
      expect { valid_issue.send_notification }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end

    it "returns false for an invalid issue" do
      invalid_issue = described_class.new(message: "")
      expect(invalid_issue.send_notification).to be_falsy
    end
  end

  describe "recipients" do
    # One address is duplicated with the facility admin
    let!(:instrument) { create(:setup_instrument, training_request_contacts: training_request_contacts) }
    let(:facility) { instrument.facility }
    let(:training_request_contacts) { "training@example.com, admin@example.com" }
    let!(:facility_admin) { create(:user, :facility_administrator, facility: facility, email: "admin@example.com") }
    let!(:facility_staff) { create(:user, :staff, facility: facility) }
    let(:instrument_issue) { described_class.new(product: instrument) }

    describe "without product-specific recipients defined" do
      it "returns the training request and admin without duplication" do
        expect(instrument_issue.recipients).to contain_exactly("training@example.com", "admin@example.com")
      end
    end

    describe "with product-specific recipients defined" do
      before { instrument.update!(issue_report_recipients: "alt1@example.com, alt2@example.com") }

      it "returns the specified recipients" do
        expect(instrument_issue.recipients).to contain_exactly("alt1@example.com", "alt2@example.com")
      end
    end
  end

end
