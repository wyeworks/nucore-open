# frozen_string_literal: true

require "rails_helper"

RSpec.describe StagingMailInterceptor do
  let(:to) { [] }
  let(:interceptor) { StagingMailInterceptor.new(message) }
  subject(:message) do
    Mail::Message.new(to: to, subject: "A message").tap do |msg|
      msg.text_part = Mail::Part.new(body: "testing")
    end
  end

  describe "allow_listing" do
    let(:allow_list) { ["allowed@example.org", "allowed2@example.org", "allowed3@example.org"] }
    let(:send_to) { ["sendto@example.org"] }

    before do
      allow(interceptor).to receive(:allow_list) { allow_list }
      allow(interceptor).to receive(:send_to_addresses) { send_to }
      interceptor.process
    end

    describe "when the email is sent to someone on the list" do
      describe "single address" do
        let(:to) { ["allowed@example.org"] }

        it "lets the email through" do
          expect(message.to).to eq(to)
        end
      end

      describe "case insensitivity" do
        let(:to) { ["ALLOWED@example.org"] }

        it "lets the message through" do
          expect(message.to).to eq(to)
        end
      end

      describe "multiple addresses" do
        let(:to) { allow_list.first(2) }

        it "lets the email through" do
          expect(message.to).to eq(to)
        end
      end

      describe "an email is included twice" do
        let(:to) { ["allowed@example.org", "allowed@example.org"] }

        it "lets the email through" do
          expect(message.to).to eq(to)
        end
      end
    end

    describe "when the email is not on the list" do
      let(:to) { ["notallowed@example.org"] }

      it "sends to the allow_list" do
        expect(message.to).to eq(send_to)
      end

      it "includes the blocked addresses in the message" do
        expect(message.text_part.body).to include("Intercepted email")
        expect(message.text_part.body).to include(*to)
      end
    end

    describe "when multiple emails are not on the list" do
      let(:to) { ["allowed@example.org", "notallowed@example.org", "notallowed2@example.org"] }

      it "sends to the allowed list" do
        expect(message.to).to eq(["allowed@example.org"])
      end

      it "includes the blocked addresses in the message" do
        expect(message.text_part.body).to include("Intercepted email")
        expect(message.text_part.body).to include(*to)
      end
    end
  end

  describe "subject manipulation" do
    before { interceptor.process }
    it "puts the site name as the prefix" do
      expect(message.subject).to eq("[#{I18n.t('app_name')} TEST] A message")
    end
  end
end
