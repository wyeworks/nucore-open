# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::Rendering do
  subject(:reservation) do
    build_stubbed(
      :reservation,
      reserve_start_at: reserve_start_at,
      reserve_end_at: reserve_end_at,
      actual_start_at: actual_start_at,
      actual_end_at: actual_end_at,
    )
  end

  let(:reserve_start_at) { nil }
  let(:reserve_end_at) { nil }
  let(:actual_start_at) { nil }
  let(:actual_end_at) { nil }

  describe "#actuals_string" do
    context "when there is an actual start_at" do
      let(:actual_start_at) { Time.zone.local(2015, 6, 1, 8, 14, 15) }

      context "and an actual end_at" do
        let(:actual_end_at) { Time.zone.local(2015, 6, 1, 9, 15, 16) }

        it "returns the formatted range" do
          expect(reservation.actuals_string)
            .to eq("Mon, 06/01/2015 8:14 AM - 9:15 AM")
        end
      end

      context "and no actual end_at" do
        it "formats the start time and uses '???' for the end time" do
          expect(reservation.actuals_string)
            .to eq("Mon, 06/01/2015 8:14 AM - ???")
        end
      end
    end

    context "when there is no actual start_at" do
      context "and there is an actual end_at" do
        let(:actual_end_at) { Time.zone.local(2015, 6, 1, 9, 15, 16) }

        it "uses '???' for the start time and formats the end time" do
          expect(reservation.actuals_string)
            .to eq("??? - Mon, 06/01/2015 9:15 AM")
        end
      end

      context "and there is no actual end_at" do
        it "returns a no actual times message" do
          expect(reservation.actuals_string).to eq("No actual times recorded")
        end
      end
    end
  end

  describe "#as_calendar_object", time_zone: "America/Chicago" do
    let(:actual_start_at) { Time.zone.local(2015, 8, 1, 9, 15, 16) }
    let(:actual_end_at) { Time.zone.local(2015, 8, 1, 10, 16, 17) }
    let(:title) { "Admin Hold" }

    let(:base_hash) do
      {
        start: "2015-08-01T09:15:16-05:00",
        end: "2015-08-01T10:16:17-05:00",
        product: "Generic",
        allDay: false,
        id: reservation.id,
      }
    end

    before { reservation.product = build_stubbed(:product, name: "Generic") }

    context "with an order" do
      let(:facility) { build_stubbed(:facility) }
      let(:order_detail) { build_stubbed(:order_detail, note: "Note to self...") }
      let(:order) { build_stubbed(:order, user: user, facility: facility, order_details: [order_detail]) }
      let(:user) { build_stubbed(:user) }

      before { allow(reservation).to receive(:order).and_return(order) }
      before { allow(reservation).to receive(:order_detail).and_return(order_detail) }

      context "with details requested" do
        let(:title) { user.full_name }

        it "returns a hash with extra details about the order" do
          expect(reservation.as_calendar_object(with_details: true))
            .to eq(base_hash.merge(email: user.email, title: user.full_name, orderId: order.id, orderNote: "Note to self..."))
        end
      end

      context "without details requested" do
        it "returns a hash without extra details about the order" do
          expect(reservation.as_calendar_object).to eq(base_hash.merge(title: "Reservation"))
        end
      end
    end

    context "without an order" do
      subject(:reservation) do
        build_stubbed(
          :admin_reservation,
          reserve_start_at:,
          reserve_end_at:,
          actual_start_at:,
          actual_end_at:,
          created_by: user,
          user_note: "this is a note",
        )
      end

      let(:user) { FactoryBot.build(:user) }

      before do
        base_hash.merge!(className: "unavailable")
      end

      context "with details requested" do
        it "returns a hash without extra details about the order" do
          expect(reservation.as_calendar_object(with_details: true))
            .to eq(base_hash.merge(title: "Admin Hold", email: user.full_name, userNote: reservation.user_note))
        end
      end

      context "without details requested" do
        it "returns a hash without extra details about the order" do
          expect(reservation.as_calendar_object).to eq(base_hash.merge(title: "Admin Hold", email: user.full_name, userNote: reservation.user_note))
        end
      end
    end
  end

  describe "#display_start_at" do
    context "when there is an actual start time" do
      let(:actual_start_at) { 4.hours.ago }

      it "returns the actual start time" do
        expect(reservation.display_start_at).to eq(reservation.actual_start_at)
      end
    end

    context "when there is no actual start time" do
      context "and there is a reserve start time" do
        let(:reserve_start_at) { 5.hours.ago }

        it "returns the reserve start time" do
          expect(reservation.display_start_at).to eq(reserve_start_at)
        end
      end

      context "and there is no reserve start time" do
        it "returns blank" do
          expect(reservation.display_start_at).to be_blank
        end
      end
    end
  end

  describe "#display_end_at" do
    context "when there is an actual end time" do
      let(:actual_end_at) { 3.hours.ago }

      it "returns the actual end time" do
        expect(reservation.display_end_at).to eq(actual_end_at)
      end
    end

    context "when there is no actual end time" do
      context "and there is a reserve end time" do
        let(:reserve_end_at) { 2.hours.ago }

        it "returns the reserve end time" do
          expect(reservation.display_end_at).to eq(reserve_end_at)
        end
      end

      context "and there is no reserve end time" do
        it "returns blank" do
          expect(reservation.display_end_at).to be_blank
        end
      end
    end
  end

  describe "#reserve_to_s" do
    let(:reserve_start_at) { Time.zone.local(2015, 5, 1, 8, 14, 15) }
    let(:reserve_end_at) { Time.zone.local(2015, 5, 1, 9, 15, 16) }

    it "formats the reservation start and end time range" do
      expect(reservation.reserve_to_s)
        .to eq("Fri, 05/01/2015 8:14 AM - 9:15 AM")
    end
  end

  describe "#to_s" do
    context "when there are reserve start and end times" do
      let(:reserve_start_at) { Time.zone.local(2015, 7, 1, 8, 14, 15) }
      let(:reserve_end_at) { Time.zone.local(2015, 7, 1, 9, 15, 16) }

      context "and the reservation is not canceled" do
        it "returns the formatted range" do
          expect(reservation.to_s).to eq("Wed, 07/01/2015 8:14 AM - 9:15 AM")
        end
      end

      context "and the reservation is canceled" do
        before { expect(reservation).to receive(:canceled?).and_return(true) }

        it "returns the formatted range with '(Canceled)' appended" do
          expect(reservation.to_s)
            .to eq("Wed, 07/01/2015 8:14 AM - 9:15 AM (Canceled)")
        end
      end
    end
  end
end
