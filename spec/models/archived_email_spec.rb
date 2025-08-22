# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArchivedEmail do
  it { is_expected.to belong_to(:log_event) }

  let(:log_event) { create(:log_event) }
  let(:archived_email) { described_class.new(log_event:) }
  let(:email_content) { "From: test@example.com\r\nTo: user@example.com\r\n\r\nBody" }

  describe "#attach_email" do
    it "attaches email with correct content type" do
      archived_email.attach_email(email_content)
      expect(archived_email.email_file).to be_attached
      expect(archived_email.email_file.content_type).to eq("message/rfc822")
    end
  end

  describe "#email_content" do
    before do
      archived_email.attach_email(email_content)
      archived_email.save!
    end

    it "retrieves stored content" do
      expect(archived_email.email_content).to eq(email_content)
    end
  end

  describe "#email_file_present?" do
    it "returns true when attached" do
      archived_email.attach_email(email_content)
      expect(archived_email.email_file_present?).to be true
    end
  end

  describe "log event association" do
    it "is destroyed with log event" do
      archived_email.attach_email(email_content)
      archived_email.save!
      expect { log_event.destroy }.to change { described_class.count }.by(-1)
    end
  end
end
