# frozen_string_literal: true

require "rails_helper"

RSpec.describe AutoEndReservationMailer do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, facility: facility, contact_email: "default@example.com") }
  let(:user) { create(:user) }
  let(:ended_by_user) { create(:user) }
  let(:reservation) { create(:purchased_reservation, product: instrument, user: user, actual_end_at: Time.current) }
  let(:mail) { described_class.notify_auto_ended(reservation, ended_by_user) }

  describe "#notify_auto_ended" do
    it "renders the headers" do
      expect(mail.subject).to eq("#{facility.abbreviation} - Your #{instrument.name} reservation has been automatically ended")
      expect(mail.to).to eq([user.email])
      expect(mail.reply_to).to eq([facility.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(user.full_name)
      expect(mail.body.encoded).to match(instrument.name)
      expect(mail.body.encoded).to match(facility.name)
      expect(mail.body.encoded).to match("automatically ended")
    end

    context "when facility has no email" do
      before do
        facility.update!(email: nil)
      end

      it "uses default reply-to" do
        expect(mail.reply_to).to eq([Settings.email.from])
      end
    end
  end
end
