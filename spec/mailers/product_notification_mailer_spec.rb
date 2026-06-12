# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductNotificationMailer do
  describe "slot_available" do
    let(:product) { create(:setup_instrument) }
    let(:facility) { product.facility }
    let(:user) { create(:user) }
    let(:start_time) { 1.hour.from_now }
    let(:end_time) { start_time + 30.minutes }
    let(:email) do
      described_class.slot_available(
        product, user, start_time, end_time,
      )
    end

    it "includes new reservation link" do
      expect(email.to).to eq [user.email]
      expect(email.body).to include(new_facility_instrument_single_reservation_path(facility, product))
    end
  end
end
