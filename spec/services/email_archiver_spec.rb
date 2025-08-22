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
    it "creates archived email" do
      expect { archiver.archive! }.to change(ArchivedEmail, :count).by(1)
    end

    it "associates with log event" do
      archiver.archive!
      expect(log_event.reload.archived_email).to be_present
    end

    it "stores complete email" do
      archiver.archive!
      content = log_event.reload.archived_email.email_content
      expect(content).to include("From: sender@example.com")
      expect(content).to include("To: recipient@example.com")
      expect(content).to include("Subject: Test Email")
      expect(content).to include("Email body")
    end

    context "invalid inputs" do
      it "does nothing without mail message" do
        archiver = described_class.new(mail_message: nil, log_event:)
        expect { archiver.archive! }.not_to change(ArchivedEmail, :count)
      end

      it "does nothing without log event" do
        archiver = described_class.new(mail_message:, log_event: nil)
        expect { archiver.archive! }.not_to change(ArchivedEmail, :count)
      end

      it "does nothing with duplicate archive" do
        archiver.archive!
        new_archiver = described_class.new(mail_message:, log_event:)
        expect { new_archiver.archive! }.not_to change(ArchivedEmail, :count)
      end
    end

  end
end
