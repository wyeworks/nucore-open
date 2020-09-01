# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkEmail::Mailer do
  describe ".mail" do
    let(:email) { ActionMailer::Base.deliveries.last }
    let(:recipient) { FactoryBot.build_stubbed(:user) }
    let(:custom_subject) { "Custom subject" }
    let(:body) { "Custom message" }
    let(:reply_to) { "reply@example.com" }
    let(:args) { { body: body, subject: custom_subject, recipient: recipient, facility: nil } }

    before do
      described_class.send_mail(args).deliver_now
    end

    it "has correct content", :aggregate_failures do
      expect(email.to).to eq [recipient.email]
      expect(email.subject).to eq(custom_subject)
      expect(email.html_part.to_s).to include(body)
      expect(email.text_part.to_s).to include(body)
    end

    context "with a single facility sender" do
      let(:facility) { FactoryBot.build_stubbed(:facility) }
      let(:args) { { body: body, subject: custom_subject, recipient: recipient, facility: facility } }

      it "includes the facility name as the sender" do
        expect(email.to_s).to include("From: #{facility.name} <#{Settings.email.from}>")
      end
    end

    context "with a single facility sender with a comma in the name" do
      let(:facility) { FactoryBot.build_stubbed(:facility, name: "Testing, Testing, and More Testing") }
      let(:args) { { body: body, subject: custom_subject, recipient: recipient, facility: facility } }

      it "includes the facility name as the sender" do
        expect(email.to_s).to include("From: \"Testing, Testing, and More Testing\" <#{Settings.email.from}>")
      end
    end

    context "with cross-facility sender" do
      let(:facility) { Facility.cross_facility }
      let(:args) { { body: body, subject: custom_subject, recipient: recipient, facility: facility } }

      it "does not include a facility name" do
        expect(email.to_s).to include("From: #{Settings.email.from}")
      end
    end

    context "with a nil facility" do
      it "does not include a facility name" do
        expect(email.to_s).to include("From: #{Settings.email.from}")
      end
    end

    context "with reply_to set" do
      let(:args) { { body: body, subject: custom_subject, recipient: recipient, reply_to: reply_to, facility: nil } }

      it { expect(email.reply_to).to eq [reply_to] }
    end

    context "without reply_to set" do
      it { expect(email.reply_to).to be_nil }
    end
  end
end
