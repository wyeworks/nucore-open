# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductNotificationMailer do
  describe "slot_available" do
    let(:product) { create(:setup_instrument) }
    let(:facility) { product.facility }
    let(:user) { create(:user) }
    let(:start_time) { 1.hour.from_now }
    let(:end_time) { start_time + 30.minutes }
    let(:mail_subject) { nil }
    let(:mail) do
      described_class.slot_available(
        product, user, start_time, end_time, subject: mail_subject,
      )
    end

    it "includes new reservation link" do
      expect(mail.to).to eq [user.email]
      expect(mail.body).to include(new_facility_instrument_single_reservation_path(facility, product))
    end

    describe "subject" do
      it "handles subject by default" do
        expect(mail.subject).to include("New availability for #{product.name}")
      end

      context "can override subject" do
        let(:mail_subject) { "Some subject" }

        it { expect(mail.subject).to eq(mail_subject) }
      end
    end
  end
end
