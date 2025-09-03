# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailArchiver do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }
  let(:statement) { create(:statement, facility:) }
  let(:log_event) { LogEvent.log(statement, :create, user) }
  let(:mail_message) do
    Mail::Message.new do
      from "sender@example.com"
      to "recipient@example.com"
      subject "Test Email"
      body "Email body"
    end
  end
  let(:archiver) { described_class.new(mail_message:, log_event:) }

  describe "#archive!" do
    it "attaches email file to log event" do
      archiver.archive!
      expect(log_event.reload.email_file_present?).to be true
    end

    it "stores complete email" do
      archiver.archive!
      content = log_event.reload.email_content
      expect(content).to include("From: sender@example.com")
      expect(content).to include("To: recipient@example.com")
      expect(content).to include("Subject: Test Email")
      expect(content).to include("Email body")
    end

    context "invalid inputs" do
      it "does nothing without mail message" do
        archiver = described_class.new(mail_message: nil, log_event:)
        result = archiver.archive!
        expect(result).to be_nil
        expect(log_event.reload.email_file_present?).to be false
      end

      it "does nothing without log event" do
        archiver = described_class.new(mail_message:, log_event: nil)
        result = archiver.archive!
        expect(result).to be_nil
      end

      it "does nothing with duplicate archive" do
        archiver.archive!
        expect(log_event.reload.email_file_present?).to be true

        new_archiver = described_class.new(mail_message:, log_event:)
        result = new_archiver.archive!
        expect(result).to be_nil
      end
    end

  end
end
