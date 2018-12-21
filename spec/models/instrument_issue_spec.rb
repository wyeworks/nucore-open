# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentIssue do

  describe "validations" do
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:product) }
  end

  describe "send_notification", active_job: :test do
    let(:valid_issue) { described_class.new(user: create(:user), product: create(:setup_instrument), message: "Hello") }

    it "returns a truthy value" do
      expect(valid_issue.send_notification).to be_truthy
    end

    it "triggers an email" do
      expect { valid_issue.send_notification }.to have_enqueued_job(ActionMailer::DeliveryJob)
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

    it "returns the training request and admin without duplication" do
      expect(instrument_issue.recipients).to contain_exactly("training@example.com", "admin@example.com")
    end
  end

end
