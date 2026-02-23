# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Instrument Relay Tab", feature_setting: { disable_relay_synaccess_rev_a: false } do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:user) { FactoryBot.create(:user, :administrator) }

  before do
    login_as user
    visit facility_instrument_relays_path(facility, instrument)
  end

  context "the instrument has no relay" do
    let(:instrument) { FactoryBot.create(:instrument, no_relay: true, facility: facility) }

    it "renders the page" do
      expect(page).to have_content("Reservation only")
    end

    context "creating a new relay" do
      before do
        click_link "Edit"
      end

      it "renders the page" do
        expect(page.current_path).to eq new_facility_instrument_relay_path(facility, instrument, instrument.relay)
      end

      it "saves a new relay" do
        expect_any_instance_of(RelaySynaccessRevA).to receive(:activate_secondary_outlet).and_return(true)
        select "Timer with relay", from: "Control mechanism"
        fill_in "relay_ip", with: "123.456.789"
        fill_in "relay_ip_port", with: "1234"
        fill_in "relay_outlet", with: "1"
        fill_in "relay_secondary_outlet", with: "2"
        fill_in "relay_username", with: "root"
        fill_in "relay_password", with: "root"
        fill_in "relay_mac_address", with: "123abc456"
        fill_in "relay_building_room_number", with: "1a"
        fill_in "relay_circuit_number", with: "1"
        fill_in "relay_ethernet_port_number", with: "2000"

        click_button "Save"
        instrument.reload
        expect(instrument.relay).to be_present
        expect(instrument.relay.ip).to eq("123.456.789")
        expect(instrument.relay.ip_port).to eq(1234)
        expect(instrument.relay.outlet).to eq(1)
        expect(instrument.relay.secondary_outlet).to eq(2)
        expect(instrument.relay.username).to eq("root")
        expect(instrument.relay.password).to eq("root")
        expect(instrument.relay.mac_address).to eq("123abc456")
        expect(instrument.relay.building_room_number).to eq("1a")
        expect(instrument.relay.circuit_number).to eq("1")
        expect(instrument.relay.ethernet_port_number).to eq("2000")
      end

      it "raises an error if there's no outlet entered" do
        select "Timer with relay", from: "Control mechanism"
        fill_in "relay_ip", with: "123.456.789"
        fill_in "relay_ip_port", with: "1234"
        fill_in "relay_username", with: "root"
        fill_in "relay_password", with: "root"
        click_button "Save"

        expect(page).to have_content("Outlet may not be blank")
        expect(page).to have_content("Outlet is not a valid number")
      end

      it "raises an error if there's no ip entered" do
        select "Timer with relay", from: "Control mechanism"
        fill_in "relay_outlet", with: "1"
        fill_in "relay_ip_port", with: "1234"
        fill_in "relay_username", with: "root"
        fill_in "relay_password", with: "root"
        click_button "Save"

        expect(page).to have_content("IP Address may not be blank")
      end

      it "raises an error if there's no username or password entered" do
        select "Timer with relay", from: "Control mechanism"
        fill_in "relay_ip", with: "123.456.789"
        fill_in "relay_ip_port", with: "1234"
        fill_in "relay_outlet", with: "1"
        click_button "Save"

        expect(page).to have_content("Username may not be blank")
        expect(page).to have_content("Password may not be blank")
      end

      context "a director can create a relay" do
        let(:user) { FactoryBot.create(:user, :facility_director, facility: facility) }

        it "saves a new relay" do
          expect_any_instance_of(RelaySynaccessRevA).to receive(:activate_secondary_outlet).and_return(true)
          select "Timer with relay", from: "Control mechanism"
          fill_in "relay_ip", with: "123.456.789"
          fill_in "relay_ip_port", with: "1234"
          fill_in "relay_outlet", with: "1"
          fill_in "relay_secondary_outlet", with: "2"
          fill_in "relay_username", with: "root"
          fill_in "relay_password", with: "root"
          fill_in "relay_mac_address", with: "123abc456"
          fill_in "relay_building_room_number", with: "1a"
          fill_in "relay_circuit_number", with: "1"
          fill_in "relay_ethernet_port_number", with: "2000"

          click_button "Save"
          instrument.reload
          expect(instrument.relay).to be_present
          expect(instrument.relay.ip).to eq("123.456.789")
          expect(instrument.relay.ip_port).to eq(1234)
          expect(instrument.relay.outlet).to eq(1)
          expect(instrument.relay.secondary_outlet).to eq(2)
          expect(instrument.relay.username).to eq("root")
          expect(instrument.relay.password).to eq("root")
          expect(instrument.relay.mac_address).to eq("123abc456")
          expect(instrument.relay.building_room_number).to eq("1a")
          expect(instrument.relay.circuit_number).to eq("1")
          expect(instrument.relay.ethernet_port_number).to eq("2000")
        end
      end

      context "the relay has already been taken by a different instrument" do
        let!(:instrument2) { create(:instrument, facility: facility, no_relay: true) }
        let!(:existing_relay) { create(:relay_synb, instrument: instrument2) }

        it "raises an error" do
          select "Timer with relay", from: "Control mechanism"
          fill_in "relay_ip", with: existing_relay.ip
          fill_in "relay_ip_port", with: existing_relay.ip_port
          fill_in "relay_outlet", with: existing_relay.outlet
          fill_in "relay_username", with: "root"
          fill_in "relay_password", with: "root"

          click_button "Save"
          expect(page).to have_content("Outlet has already been taken")
        end

        context "both instruments have the same schedule" do
          let!(:instrument2) { create(:instrument, facility: facility, no_relay: true, schedule: instrument.schedule) }
          let!(:existing_relay) { create(:relay_syna, instrument: instrument2) }

          it "saves the relay" do
            # existing relay has no secondary outlet, so this should not be called
            expect_any_instance_of(RelaySynaccessRevA).not_to receive(:activate_secondary_outlet)
            select "Timer with relay", from: "Control mechanism"
            select "Synaccess Revision A", from: "Relay Type"
            fill_in "relay_ip", with: existing_relay.ip
            fill_in "relay_ip_port", with: existing_relay.ip_port
            fill_in "relay_outlet", with: existing_relay.outlet
            fill_in "relay_username", with: "root"
            fill_in "relay_password", with: "root"

            click_button "Save"
            expect(page).to have_content("Relay was successfully updated.")
          end
        end
      end
    end
  end

  context "editing an existing relay" do
    let(:instrument) { FactoryBot.create(:setup_instrument, facility: facility, relay: build(:relay)) }

    before do
      click_link "Edit"
    end

    it "renders the page" do
      expect(page.current_path).to eq edit_facility_instrument_relay_path(facility, instrument, instrument.relay)
    end

    it "can be saved" do
      expect_any_instance_of(RelaySynaccessRevA).to receive(:activate_secondary_outlet).and_return(true)
      select "Timer with relay", from: "Control mechanism"
      fill_in "relay_ip", with: "123.456.789"
      fill_in "relay_ip_port", with: "1234"
      fill_in "relay_outlet", with: "1"
      fill_in "relay_secondary_outlet", with: "2"
      fill_in "relay_username", with: "root"
      fill_in "relay_password", with: "root"
      fill_in "relay_mac_address", with: "123abc456"
      fill_in "relay_building_room_number", with: "1a"
      fill_in "relay_circuit_number", with: "1"
      fill_in "relay_ethernet_port_number", with: "2000"

      click_button "Save"
      instrument.reload
      expect(instrument.relay.ip).to eq("123.456.789")
      expect(instrument.relay.ip_port).to eq(1234)
      expect(instrument.relay.outlet).to eq(1)
      expect(instrument.relay.secondary_outlet).to eq(2)
      expect(instrument.relay.username).to eq("root")
      expect(instrument.relay.password).to eq("root")
      expect(instrument.relay.mac_address).to eq("123abc456")
      expect(instrument.relay.building_room_number).to eq("1a")
      expect(instrument.relay.circuit_number).to eq("1")
      expect(instrument.relay.ethernet_port_number).to eq("2000")
    end
  end

  context "switching relay types" do
    let(:instrument) { FactoryBot.create(:setup_instrument, facility: facility, relay: build(:relay)) }

    before do
      click_link "Edit"
    end

    context "from relay to timer" do
      it "it deletes the relay and assigns the instrument a RelayDummy" do
        select "Timer without relay", from: "Control mechanism"

        click_button "Save"
        instrument.reload

        expect(instrument.relay).to be_a(RelayDummy)
      end

    end

    context "from relay to reservation only" do

      it "deletes the relay" do
        select "Reservation only", from: "Control mechanism"

        click_button "Save"
        instrument.reload

        expect(instrument.relay).not_to be_present
      end

      it "does leaves a hanging relay" do
        select "Reservation only", from: "Control mechanism"

        click_button "Save"

        expect(Relay.exists?(instrument_id: nil)).to be false
      end

    end

    context "from reservation only to timer" do
      let(:instrument) { FactoryBot.create(:instrument, facility: facility, no_relay: true) }

      it "sets the instrument relay to a RelayDummy" do
        select "Timer without relay", from: "Control mechanism"

        click_button "Save"
        instrument.reload

        expect(instrument.relay).to be_a(RelayDummy)
      end
    end

    context "from timer to reservation only" do
      let(:instrument) { FactoryBot.create(:setup_instrument, facility: facility) }

      it "deletes the relay dummy" do
        select "Reservation only", from: "Control mechanism"

        click_button "Save"
        instrument.reload

        expect(instrument.relay).not_to be_present
      end
    end
  end
end
