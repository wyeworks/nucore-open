# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Secure Room Ethernet Ports" do
    let(:facility) { FactoryBot.create(:setup_facility) }
    let(:user) { FactoryBot.create(:user, :administrator) }
    let(:room) { FactoryBot.create(:secure_room, name: "test room", facility: facility) }

    before do
      login_as user
      visit facility_secure_room_card_readers_path(facility, room)
      click_link "Edit Ethernet Ports"
    end

    it "renders the page" do
      expect(page.current_path).to eq edit_facility_secure_room_ethernet_port_path(facility, room)
    end

    it "can be saved" do
      fill_in "secure_room_card_reader_room_number", with: "1a"
      fill_in "secure_room_card_reader_circuit_number", with: "1"
      fill_in "secure_room_card_reader_port_number", with: "3000"
      fill_in "secure_room_card_reader_location_description", with: "The card reader is near the tablet"
      fill_in "secure_room_tablet_room_number", with: "1a"
      fill_in "secure_room_tablet_circuit_number", with: "2"
      fill_in "secure_room_tablet_port_number", with: "4000"
      fill_in "secure_room_tablet_location_description", with: "The tablet is near the card reader"

      click_button "Save"
      room.reload

      expect(room.card_reader_room_number).to eq("1a")
      expect(room.card_reader_circuit_number).to eq("1")
      expect(room.card_reader_port_number).to eq(3000)
      expect(room.card_reader_location_description).to eq("The card reader is near the tablet")
      expect(room.tablet_room_number).to eq("1a")
      expect(room.tablet_circuit_number).to eq("2")
      expect(room.tablet_port_number).to eq(4000)
      expect(room.tablet_location_description).to eq("The tablet is near the card reader")
    end
end
