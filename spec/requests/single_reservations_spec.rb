# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SingleReservationsController" do
  describe "new" do
    let(:user) { create(:user) }
    let(:instrument) { create(:setup_instrument) }
    let(:facility) { instrument.facility }

    let(:action) do
      lambda do |params = {}|
        get new_facility_instrument_single_reservation_path(facility, instrument, **params)
      end
    end

    before do
      login_as user
    end

    context "when start_at param is provided" do
      let(:start_at) { 1.day.from_now }

      it "finds next available with that value" do
        expect(NextAvailableReservationFinder).to(
          receive(:new)
          .with(instrument, start_at:)
        ).and_call_original

        action.call(start_at:)
      end

      context "when start at is invalid" do
        let(:start_at) { "Some invalid date" }

        it "finds next available with start_at nil" do
          expect(NextAvailableReservationFinder).to(
            receive(:new)
            .with(instrument, start_at: nil)
          ).and_call_original

          action.call(start_at:)
        end
      end
    end
  end
end
