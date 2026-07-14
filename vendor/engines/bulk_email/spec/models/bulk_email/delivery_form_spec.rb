# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkEmail::DeliveryForm do
  subject(:form) { described_class.new(user, facility, content_generator) }
  let(:content_generator) { BulkEmail::ContentGenerator.new(facility) }
  let(:facility) { FactoryBot.create(:facility) }
  let(:recipients) { FactoryBot.create_list(:user, 3) }
  let(:user) { FactoryBot.create(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:recipient_ids) }

    context "there is no product" do
      it { is_expected.to validate_presence_of(:custom_subject) }
      it { is_expected.to validate_presence_of(:custom_message) }
    end

    context "there is an online instrument" do
      before do
        allow(form).to receive(:product).and_return double("Instrument", offline?: false)
      end
      it { is_expected.to validate_presence_of(:custom_subject) }
      it { is_expected.to validate_presence_of(:custom_message) }
    end

    context "when there is an offline instrument" do
      before do
        allow(form).to receive(:product).and_return double("Instrument", offline?: true)
      end

      it { is_expected.not_to validate_presence_of(:custom_subject) }
      it { is_expected.not_to validate_presence_of(:custom_message) }
    end

    context "custom_reply_to" do
      it { is_expected.to allow_value("reply@example.com").for(:custom_reply_to) }
      it { is_expected.to allow_value("").for(:custom_reply_to) }
      it { is_expected.to allow_value(nil).for(:custom_reply_to) }
      it { is_expected.not_to allow_value("not-an-email").for(:custom_reply_to) }
    end
  end

  describe "#assign_attributes" do
    it "strips surrounding whitespace from custom_reply_to" do
      form.assign_attributes(custom_reply_to: "  reply@example.com  ")
      expect(form.custom_reply_to).to eq("reply@example.com")
    end
  end

  describe "#reply_to" do
    subject(:reply_to) { form.send(:reply_to) }

    context "when custom_reply_to is set" do
      before { form.custom_reply_to = "custom@example.com" }

      it "uses the custom value" do
        expect(reply_to).to eq("custom@example.com")
      end
    end

    context "when custom_reply_to is blank" do
      before { form.custom_reply_to = "" }

      context "and the product has a contact email" do
        before do
          allow(form).to receive(:product).and_return double("Product", contact_email: "product@example.com")
        end

        it "uses the product contact email" do
          expect(reply_to).to eq("product@example.com")
        end
      end

      context "and there is no product" do
        it "falls back to the facility email" do
          expect(reply_to).to eq(facility.email)
        end
      end
    end
  end

  describe "#deliver_all" do
    before(:each) do
      recipients.each do |recipient|
        expect(form).to receive(:deliver).with(recipient)
      end

      form.recipient_ids = recipients.map(&:id)
      form.custom_subject = "Subject line"
      form.custom_message = "Custom message"
      form.search_criteria = { this: "is", a: "test" }

      allow(content_generator).to receive(:greeting).and_return("Greeting")
      allow(content_generator).to receive(:subject_prefix).and_return("Prefix")
    end

    let(:bulk_email_job) { BulkEmail::Job.last }

    shared_examples_for "it delivers mail" do
      it "queues mail to all recipients", :aggregate_failures do
        expect { form.deliver_all }.to change(BulkEmail::Job, :count).by(1)
        expect(bulk_email_job.subject).to eq("Prefix #{form.custom_subject}")
        expect(bulk_email_job.body).to eq(expected_body)
        expect(bulk_email_job.recipients).to match_array(recipients.map(&:email))
        expect(bulk_email_job.search_criteria).to match(this: "is", a: "test")
        expect(bulk_email_job.reply_to).to eq(form.send(:reply_to))
      end
    end

    context "when in a single-facility context" do
      let(:expected_body) { "Greeting\n\nCustom message" }

      it_behaves_like "it delivers mail"
    end

    context "when in a cross-facility context" do
      let(:expected_body) { "Greeting\n\nCustom message" }
      let(:facility) { Facility.cross_facility }

      it_behaves_like "it delivers mail"
    end
  end

  describe "the reply-to passed to the mailer" do
    let(:mailer) { double("mailer", deliver_later: true) }

    before do
      form.recipient_ids = recipients.map(&:id)
      form.custom_subject = "Subject line"
      form.custom_message = "Custom message"
      form.search_criteria = { this: "is", a: "test" }
      allow(BulkEmail::Mailer).to receive(:send_mail).and_return(mailer)
    end

    context "when a custom reply-to is given" do
      before { form.custom_reply_to = "reply@example.com" }

      it "passes it to the mailer" do
        form.deliver_all
        expect(BulkEmail::Mailer).to have_received(:send_mail)
          .with(hash_including(reply_to: "reply@example.com"))
          .exactly(recipients.count).times
      end

      it "records it on the job" do
        form.deliver_all
        expect(BulkEmail::Job.last.reply_to).to eq("reply@example.com")
      end
    end

    context "when the custom reply-to is blank" do
      before { form.custom_reply_to = "" }

      it "falls back to the facility email" do
        form.deliver_all
        expect(BulkEmail::Mailer).to have_received(:send_mail)
          .with(hash_including(reply_to: facility.email))
          .exactly(recipients.count).times
      end
    end
  end
end
