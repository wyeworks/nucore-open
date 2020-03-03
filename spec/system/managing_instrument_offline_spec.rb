# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing Instrument Offline Reservations" do

  before { login_as administrator }

  let(:administrator) { FactoryBot.create(:user, :administrator) }
  let(:facility) { instrument.facility }
  let(:instrument) { FactoryBot.create(:setup_instrument) }

  describe "marking an instrument offline" do
    before(:each) do
      visit facility_instrument_schedule_path(facility, instrument)
      click_link "Mark Instrument Offline"
      fill_in "offline_reservation[admin_note]", with: "The instrument is broken"
      click_button "Take instrument offline"
    end

    it "marks the instrument offline" do
      expect(page).to have_content("The instrument has been marked offline")
    end

    describe "editing the note of an ongoing offline reservation" do
      let(:offline_reservation) { instrument.offline_reservations.last }

      before(:each) do
        visit edit_facility_instrument_offline_reservation_path(facility, instrument, offline_reservation)
      end

      context "when the admin_note has content" do
        before(:each) do
          fill_in "offline_reservation[admin_note]", with: "The instrument is being repaired"
          click_button "Update the note"
        end

        it "updates the note" do
          expect(page).to have_content "The downtime note has been updated"
          expect(current_path)
            .to eq(facility_instrument_schedule_path(facility, instrument))
          expect(offline_reservation.reload.admin_note)
            .to eq("The instrument is being repaired")
        end
      end

      context "when the admin_note is blank" do
        before(:each) do
          fill_in "offline_reservation[admin_note]", with: ""
          click_button "Update the note"
        end

        it "does not update the note" do
          expect(page).to have_content "Admin Note may not be blank"
          expect(current_path)
            .to eq(facility_instrument_offline_reservation_path(facility, instrument, offline_reservation))
          expect(offline_reservation.reload.admin_note)
            .to eq("The instrument is broken")
        end
      end
    end
  end

  describe "taking an offline instrument back online" do
    before(:each) do
      instrument
        .offline_reservations
        .create!(
          reserve_start_at: 1.hour.ago,
          admin_note: "It's broken",
          category: "out_of_order",
        )

      visit facility_instrument_schedule_path(facility, instrument)
      click_link "Bring Instrument Online"
    end

    it "brings the instrument back online" do
      expect(page).to have_content "The instrument is back online"
      expect(current_path)
        .to eq(facility_instrument_schedule_path(facility, instrument))
      expect(instrument.reload).to be_online
    end
  end
end
