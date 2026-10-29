# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReservationCalendar, :aggregate_failures do
  let(:order) { build_stubbed(:order) }
  let(:order_detail) { build_stubbed(:order_detail, order: order) }
  let(:reservation) do
    build_stubbed(:reservation,
                  reserve_start_date: 1.day.from_now.to_date,
                  reserve_start_hour: 10,
                  reserve_start_min: 0,
                  reserve_start_meridian: "am",
                  duration_mins: 60,
                  split_times: true,
                  order: order,
                  order_detail: order_detail)
  end
  let(:calendar) { ReservationCalendar.new(reservation) }
  let(:facility) { build(:facility, name: "Facility", abbreviation: "FA") }
  let(:ical) { calendar.ical }

  before(:each) do
    allow(reservation).to receive_message_chain(:product, :name)
      .and_return("Instrument")
    allow(reservation).to receive(:facility).and_return(facility)
  end

  describe "#as_ical" do
    it "generates an ical file" do
      expect(ical.events.size).to eq(1)
      event = ical.events.first
      expect(event.dtstart).to eq(reservation.reserve_start_at)
      expect(event.dtend).to eq(reservation.reserve_end_at)
      expect(event.summary).to eq("FA: Instrument")
      expect(event.description).to eq("Facility reservation for Instrument. Order number #{order_detail.order_number}.")
      expect(event.location).to eq("Facility")
      expect(event.url.to_s).to eq("")
      expect(event.ip_class).to eq("PRIVATE")
    end
  end
end
