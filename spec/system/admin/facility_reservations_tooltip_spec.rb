# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reservation Tooltips", :js do

  # FullCalendar.io doesn't know about server time,
  # and this spec isn't sensitive to fiscal year changes,
  # so we're using system time instead of the global time lock.
  before(:all) { travel_back }

  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:reserve_start) { Time.current.change(hour: 12, min: 30) }
  let!(:reservation) { create(:purchased_reservation, reserve_start_at: reserve_start, product: instrument, order_detail: order_detail) }
  let(:instrument) { create(:setup_instrument, facility: facility) }
  let(:account) { create(:account, :with_account_owner, owner: director) }
  let(:order) { create(:setup_order, account: account, product: instrument, order_detail_attributes: { note: "This is an order detail note" } ) }
  let(:order_detail) { order.order_details.first }

  before(:each) { login_as director }

  context "When show order note is enabled for the facility" do
    it "Includes the order note in the tooltip for the Admin Daily View" do
      visit timeline_facility_reservations_path(facility)

      expect(page.body).to include("This is an order detail note")
    end

    it "Includes the order note in the tooltip for the instrument reservation calendar" do
      visit facility_instrument_schedule_path(facility, instrument)

      page.find('.fc-title').hover
      expect(page.body).to include("This is an order detail note")
    end

    it "Includes the order note in the tooltip for the Admin Hold calendar" do
      visit new_facility_instrument_reservation_path(facility, instrument)

      page.find('.fc-title').hover
      expect(page.body).to include("This is an order detail note")
    end

    it "Does not include the order note in the tooltip for the public timeline calendar" do
      visit facility_public_timeline_path(facility)

      expect(page.body).not_to include("This is an order detail note")
    end

    it "Does not include the order note in the tooltip for the public instrument schedule calendar" do
      visit facility_instrument_public_schedule_path(facility, instrument)

      expect(page.body).not_to include("This is an order detail note")
    end

    it "Does not include the order note in the tooltip for the new reservation calendar" do
      visit new_facility_instrument_single_reservation_path(facility, instrument)

      expect(page.body).not_to include("This is an order detail note")
    end
  end

  context "When show order note is NOT enabled for the facility" do
    let(:facility) { create(:setup_facility, show_order_note: false) }

    it "Does not include the order note in the tooltip for the Admin Daily View" do
      visit timeline_facility_reservations_path(facility)

      expect(page.body).not_to include("This is an order detail note")
    end

    it "Does not include the order note in the tooltip for the instrument reservation calendar" do
      visit facility_instrument_schedule_path(facility, instrument)

      page.find('.fc-title').hover
      expect(page.body).not_to include("This is an order detail note")
    end

    it "Does not include the order note in the tooltip for the Admin Hold calendar" do
      visit new_facility_instrument_reservation_path(facility, instrument)

      page.find('.fc-title').hover
      expect(page.body).not_to include("This is an order detail note")
    end

    it "Does not include the order note in the tooltip for the public timeline calendar" do
      visit facility_public_timeline_path(facility)

      expect(page.body).not_to include("This is an order detail note")
    end

    it "Does not include the order note in the tooltip for the public instrument schedule calendar" do
      visit facility_instrument_public_schedule_path(facility, instrument)

      expect(page.body).not_to include("This is an order detail note")
    end

    it "Does not include the order note in the tooltip for the new reservation calendar" do
      visit new_facility_instrument_single_reservation_path(facility, instrument)

      expect(page.body).not_to include("This is an order detail note")
    end
  end

end
